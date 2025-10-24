#!/bin/bash
# Force_1 Email Quota Enforcer + Additional Features
# Handles email sending with 3800/day limit + enables useful disabled features
# Mautic's built-in crons handle segments/campaigns (every 15min)

# --- CONFIGURATION ---
MAX_EMAILS_PER_DAY=3800
EMAIL_LOG=/var/log/mautic/email_count.log
TODAY=$(date +%Y-%m-%d)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
HOUR=$(date +%H)
DAY_OF_WEEK=$(date +%u)  # 1=Monday, 7=Sunday

# --- ENSURE LOG DIRECTORY ---
mkdir -p /var/log/mautic

# --- CHANGE TO MAUTIC DIRECTORY ---
cd /var/www/html

# --- INITIALIZE/CHECK EMAIL COUNTER ---
if [ ! -f "$EMAIL_LOG" ]; then
    echo "$TODAY,0" > "$EMAIL_LOG"
fi

LAST_DATE=$(cut -d',' -f1 "$EMAIL_LOG")
COUNT=$(cut -d',' -f2 "$EMAIL_LOG")

# Reset at midnight
if [ "$LAST_DATE" != "$TODAY" ]; then
    echo "$TODAY,0" > "$EMAIL_LOG"
    COUNT=0
    echo "[$TIMESTAMP] NEW DAY: Email counter reset"
fi

# --- 1. EMAIL QUOTA ENFORCEMENT (every 10 min) ---
if [ "$COUNT" -lt "$MAX_EMAILS_PER_DAY" ]; then
    REMAINING=$((MAX_EMAILS_PER_DAY - COUNT))
    BATCH_SIZE=52
    
    if [ "$REMAINING" -lt "$BATCH_SIZE" ]; then
        BATCH_SIZE=$REMAINING
    fi
    
    echo "[$TIMESTAMP] Sending $BATCH_SIZE emails ($COUNT/$MAX_EMAILS_PER_DAY sent today)"
    
    timeout 300 php bin/console messenger:consume email --limit=$BATCH_SIZE --time-limit=300 --memory-limit=512M --no-interaction
    
    NEW_COUNT=$((COUNT + BATCH_SIZE))
    echo "$TODAY,$NEW_COUNT" > "$EMAIL_LOG"
    
    echo "[$TIMESTAMP] Email batch complete. Total today: $NEW_COUNT/$MAX_EMAILS_PER_DAY"
else
    echo "[$TIMESTAMP] QUOTA REACHED: $COUNT/$MAX_EMAILS_PER_DAY - No more emails until tomorrow"
fi

# --- 2. BOUNCE PROCESSING (every 10 min) ---
echo "[$TIMESTAMP] Processing email bounces..."
php bin/console mautic:email:fetch --no-interaction

# --- 3. WEBHOOK PROCESSING (every 10 min) ---
echo "[$TIMESTAMP] Processing webhooks..."
php bin/console mautic:webhooks:process --no-interaction

# --- 4. IMPORT/EXPORT PROCESSING (every 10 min) ---
echo "[$TIMESTAMP] Processing imports and exports..."
php bin/console mautic:import --no-interaction
php bin/console mautic:contacts:scheduled_export --no-interaction

# --- 5. HOURLY TASKS ---
if [ "${HOUR#0}" -eq 0 ] || [ $((${HOUR#0} % 1)) -eq 0 ]; then
    echo "[$TIMESTAMP] Running hourly tasks..."
    
    # Update MaxMind GeoLite2 IP database
    php bin/console mautic:iplookup:download --no-interaction
fi

# --- 6. DAILY MAINTENANCE (at 2 AM) ---
if [ "${HOUR#0}" -eq 2 ]; then
    echo "[$TIMESTAMP] Running daily maintenance..."
    
    # Clean up old data (30 days instead of 365 for safety)
    php bin/console mautic:maintenance:cleanup --days-old=30 --no-interaction
    
    # Create database backup
    echo "[$TIMESTAMP] Creating database backup..."
    mkdir -p /var/log/mautic/backups
    docker exec force_1_db mysqldump -u force_1 -pElem2025! force_1 > "/var/log/mautic/backups/force1_backup_$TODAY.sql"
    
    # Keep only last 7 days of backups
    find /var/log/mautic/backups -name "force1_backup_*.sql" -mtime +7 -delete 2>/dev/null || true
fi

# --- 7. WEEKLY TASKS (Sunday at 3 AM) ---
if [ "$DAY_OF_WEEK" -eq 7 ] && [ "${HOUR#0}" -eq 3 ]; then
    echo "[$TIMESTAMP] Running weekly MaxMind CCPA compliance tasks..."
    
    # MaxMind CCPA compliance
    php bin/console mautic:donotsell:download --no-interaction
    php bin/console mautic:max-mind:purge --no-interaction
fi

echo "[$TIMESTAMP] Cycle complete"