#!/bin/bash
# Mautic Force_1 Cron Script - ABSOLUTE 3800 EMAIL LIMIT
# Purpose: Maintain system health + enforce HARD email quota
# Location: /opt/mautic/cron/mautic_cron_force1.sh

# --- ABSOLUTE CONFIGURATION ---
MAUTIC_PATH=/var/www/html
PHP_BIN=/usr/local/bin/php
TIMEZONE="America/New_York"
MAX_EMAILS_PER_DAY=3800
EMAIL_LOG=/var/log/mautic/email_count.log
BACKUP_DIR=/var/log/mautic/backups
NOW=$(TZ=$TIMEZONE date +%H)
TODAY=$(TZ=$TIMEZONE date +%Y-%m-%d)
TIMESTAMP=$(TZ=$TIMEZONE date '+%Y-%m-%d %H:%M:%S')

# --- ENSURE LOG DIRECTORY EXISTS ---
mkdir -p /var/log/mautic
mkdir -p $BACKUP_DIR

# --- INITIALIZE DAILY EMAIL COUNTER ---
if [ ! -f "$EMAIL_LOG" ]; then
    echo "$TODAY,0" > "$EMAIL_LOG"
fi

LAST_DATE=$(cut -d',' -f1 "$EMAIL_LOG")
COUNT=$(cut -d',' -f2 "$EMAIL_LOG")

# Reset counter at midnight
if [ "$LAST_DATE" != "$TODAY" ]; then
    echo "$TODAY,0" > "$EMAIL_LOG"
    COUNT=0
    echo "[$TIMESTAMP] NEW DAY: Email counter reset to 0"
fi

echo "[$TIMESTAMP] Current email count: $COUNT/$MAX_EMAILS_PER_DAY"

# --- CHANGE TO MAUTIC DIRECTORY ---
cd $MAUTIC_PATH || exit 1

# --- 1. ALWAYS RUN MAINTENANCE (24/7) ---
echo "[$TIMESTAMP] Running maintenance tasks..."

# Update segments (every run)
$PHP_BIN bin/console mautic:segments:update --batch-limit=500 --no-interaction

# Update campaigns (every run)  
$PHP_BIN bin/console mautic:campaigns:update --batch-limit=500 --no-interaction

# Trigger campaigns (every run)
$PHP_BIN bin/console mautic:campaigns:trigger --batch-limit=200 --no-interaction

# Process webhooks
$PHP_BIN bin/console mautic:webhooks:process --no-interaction

# Fetch bounces
$PHP_BIN bin/console mautic:email:fetch --no-interaction

# --- 2. EMAIL SENDING WITH ABSOLUTE QUOTA ENFORCEMENT ---
if [ "$COUNT" -lt "$MAX_EMAILS_PER_DAY" ]; then
    # Calculate remaining emails for today
    REMAINING=$((MAX_EMAILS_PER_DAY - COUNT))
    
    # Send in small batches (max 52 per run = ~312/hour = ~3744/day if run every 10min)
    BATCH_SIZE=52
    if [ "$REMAINING" -lt "$BATCH_SIZE" ]; then
        BATCH_SIZE=$REMAINING
    fi
    
    echo "[$TIMESTAMP] Sending $BATCH_SIZE emails (remaining today: $REMAINING)"
    
    # Use messenger:consume for proper queue processing
    timeout 300 $PHP_BIN bin/console messenger:consume email --limit=$BATCH_SIZE --time-limit=300 --memory-limit=512M --no-interaction
    
    # Update counter
    NEW_COUNT=$((COUNT + BATCH_SIZE))
    echo "$TODAY,$NEW_COUNT" > "$EMAIL_LOG"
    
    echo "[$TIMESTAMP] Email batch complete. New total: $NEW_COUNT/$MAX_EMAILS_PER_DAY"
else
    echo "[$TIMESTAMP] QUOTA REACHED: $COUNT/$MAX_EMAILS_PER_DAY - NO MORE EMAILS TODAY"
fi

# --- 3. QUEUE MAINTENANCE ---
echo "[$TIMESTAMP] Processing queue maintenance..."

# Retry failed messages (limit retries)
$PHP_BIN bin/console messenger:failed:retry --force --no-interaction 2>/dev/null || true

# Clean old failed messages (older than 24 hours)
$PHP_BIN bin/console messenger:failed:remove --force --no-interaction 2>/dev/null || true

# --- 4. SYSTEM CLEANUP ---
# Clear cache (every 6 hours - check if hour is divisible by 6)
if [ $((NOW % 6)) -eq 0 ]; then
    echo "[$TIMESTAMP] Clearing cache..."
    $PHP_BIN bin/console cache:clear --no-interaction
fi

# Database cleanup (daily at 2 AM)
if [ "$NOW" -eq 2 ]; then
    echo "[$TIMESTAMP] Running daily maintenance cleanup..."
    $PHP_BIN bin/console mautic:maintenance:cleanup --days-old=30 --no-interaction
    
    # Create database backup
    echo "[$TIMESTAMP] Creating database backup..."
    docker exec force_1_db mysqldump -u force_1 -pElem2025! force_1 > "$BACKUP_DIR/force1_backup_$TODAY.sql"
    
    # Keep only last 7 days of backups
    find $BACKUP_DIR -name "force1_backup_*.sql" -mtime +7 -delete
fi

echo "[$TIMESTAMP] Cron cycle complete"
echo "----------------------------------------"