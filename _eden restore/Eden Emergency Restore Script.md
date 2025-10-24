`#!/bin/bash`

`################################################################################`
# `Eden Emergency Restore Script`
# 
# `Purpose: Restore Eden marketing stack to last known-good state in <2 minutes`
# `Backup Source: /root/backups/eden_backup_20251022_231419/`
# 
# `What This Script Does:`
# `1. Stops all Eden containers`
# `2. Restores database from SQL dump`
# `3. Restores Docker volumes (config, logs, data)`
# `4. Restores docker-compose.yml`
# `5. Starts containers`
# `6. Verifies system is operational`
#
# `USAGE: ./restore_eden_emergency.sh`
# 
# `⚠️  WARNING: This will OVERWRITE current system state with backup`
`################################################################################`

`set -e  # Exit on any error`

# `Color codes for output`
`RED='\033[0;31m'`
`GREEN='\033[0;32m'`
`YELLOW='\033[1;33m'`
`NC='\033[0m' # No Color`

# `Configuration`
`BACKUP_DIR="/root/backups/eden_backup_20251022_231419"`
`PROJECT_DIR="/root"`
`DB_CONTAINER="eden_db"`
`DB_NAME="eden"`
`DB_USER="eden"`
`DB_PASS="Elem2025!"`

`echo -e "${YELLOW}╔════════════════════════════════════════════════════════╗${NC}"`
`echo -e "${YELLOW}║        Eden Emergency Restore - Starting...           ║${NC}"`
`echo -e "${YELLOW}╚════════════════════════════════════════════════════════╝${NC}"`
`echo ""`

`START_TIME=$(date +%s)`

# `Verify backup exists`
`if [ ! -d "$BACKUP_DIR" ]; then`
    `echo -e "${RED}❌ ERROR: Backup directory not found: $BACKUP_DIR${NC}"`
    `exit 1`
`fi`

`echo -e "${GREEN}✓${NC} Backup directory found: $BACKUP_DIR"`
`echo ""`

# `Step 1: Stop all containers`
`echo -e "${YELLOW}[1/6]${NC} Stopping Eden containers..."`
`cd "$PROJECT_DIR"`
`docker-compose down 2>/dev/null || true`
`echo -e "${GREEN}✓${NC} Containers stopped"`
`echo ""`

# `Step 2: Restore docker-compose.yml`
`echo -e "${YELLOW}[2/6]${NC} Restoring docker-compose configuration..."`
`if [ -f "$BACKUP_DIR/docker-compose.yml" ]; then`
    `cp "$BACKUP_DIR/docker-compose.yml" "$PROJECT_DIR/docker-compose.yml"`
    `echo -e "${GREEN}✓${NC} docker-compose.yml restored"`
`else`
    `echo -e "${RED}❌ WARNING: docker-compose.yml not found in backup${NC}"`
`fi`
`echo ""`

# `Step 3: Restore Docker volumes`
`echo -e "${YELLOW}[3/6]${NC} Restoring Docker volumes..."`

# `Config volume`
`if [ -f "$BACKUP_DIR/eden_config_volume.tar.gz" ]; then`
    `docker volume rm eden_config 2>/dev/null || true`
    `docker volume create eden_config`
    `docker run --rm -v eden_config:/dest -v "$BACKUP_DIR":/source alpine \`
        `sh -c "cd /dest && tar xzf /source/eden_config_volume.tar.gz"`
    `echo -e "${GREEN}✓${NC} Config volume restored"`
`else`
    `echo -e "${RED}❌ WARNING: Config volume backup not found${NC}"`
`fi`

# `Logs volume`
`if [ -f "$BACKUP_DIR/eden_logs_volume.tar.gz" ]; then`
    `docker volume rm eden_logs 2>/dev/null || true`
    `docker volume create eden_logs`
    `docker run --rm -v eden_logs:/dest -v "$BACKUP_DIR":/source alpine \`
        `sh -c "cd /dest && tar xzf /source/eden_logs_volume.tar.gz"`
    `echo -e "${GREEN}✓${NC} Logs volume restored"`
`fi`

# `Data volume`
`if [ -f "$BACKUP_DIR/eden_data_volume.tar.gz" ]; then`
    `docker volume rm eden_data 2>/dev/null || true`
    `docker volume create eden_data`
    `docker run --rm -v eden_data:/dest -v "$BACKUP_DIR":/source alpine \`
        `sh -c "cd /dest && tar xzf /source/eden_data_volume.tar.gz"`
    `echo -e "${GREEN}✓${NC} Data volume restored"`
`fi`

`echo ""`

# `Step 4: Start database container first`
`echo -e "${YELLOW}[4/6]${NC} Starting database container..."`
`docker-compose up -d $DB_CONTAINER`
`echo "Waiting for database to be ready..."`
`sleep 10`

# `Wait for MySQL to be ready`
`MAX_RETRIES=30`
`RETRY_COUNT=0`
`while ! docker exec $DB_CONTAINER mysqladmin ping -h localhost -u root -pElem2025! --silent 2>/dev/null; do`
    `RETRY_COUNT=$((RETRY_COUNT+1))`
    `if [ $RETRY_COUNT -ge $MAX_RETRIES ]; then`
        `echo -e "${RED}❌ ERROR: Database failed to start${NC}"`
        `exit 1`
    `fi`
    `echo "Waiting for database... ($RETRY_COUNT/$MAX_RETRIES)"`
    `sleep 2`
`done`
`echo -e "${GREEN}✓${NC} Database is ready"`
`echo ""`

# `Step 5: Restore database`
`echo -e "${YELLOW}[5/6]${NC} Restoring database..."`
`if [ -f "$BACKUP_DIR/eden_database.sql" ]; then`
    `# Drop and recreate database`
    `docker exec -i $DB_CONTAINER mysql -u root -pElem2025! -e "DROP DATABASE IF EXISTS $DB_NAME;"`
    `docker exec -i $DB_CONTAINER mysql -u root -pElem2025! -e "CREATE DATABASE $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"`
    
    `# Restore from backup`
    `docker exec -i $DB_CONTAINER mysql -u $DB_USER -p$DB_PASS $DB_NAME < "$BACKUP_DIR/eden_database.sql"`
    
    `# Verify restoration`
    `CONTACT_COUNT=$(docker exec $DB_CONTAINER mysql -u $DB_USER -p$DB_PASS $DB_NAME -se "SELECT COUNT(*) FROM leads;" 2>/dev/null || echo "0")`
    `echo -e "${GREEN}✓${NC} Database restored - Contact count: $CONTACT_COUNT"`
`else`
    `echo -e "${RED}❌ ERROR: Database backup not found${NC}"`
    `exit 1`
`fi`
`echo ""`

# `Step 6: Start all containers`
`echo -e "${YELLOW}[6/6]${NC} Starting all Eden containers..."`
`docker-compose up -d`
`echo "Waiting for services to initialize..."`
`sleep 15`
`echo -e "${GREEN}✓${NC} All containers started"`
`echo ""`

# `Verification`
`echo -e "${YELLOW}╔════════════════════════════════════════════════════════╗${NC}"`
`echo -e "${YELLOW}║              System Verification                      ║${NC}"`
`echo -e "${YELLOW}╚════════════════════════════════════════════════════════╝${NC}"`
`echo ""`

# `Check container status`
`echo "Container Status:"`
`docker-compose ps`
`echo ""`

# `Verify database connection`
`echo "Database Verification:"`
`DB_CHECK=$(docker exec $DB_CONTAINER mysql -u $DB_USER -p$DB_PASS $DB_NAME -se "SELECT COUNT(*) FROM leads;" 2>/dev/null || echo "FAILED")`
`if [ "$DB_CHECK" != "FAILED" ]; then`
    `echo -e "${GREEN}✓${NC} Database connection: OK"`
    `echo -e "${GREEN}✓${NC} Contact count: $DB_CHECK"`
`else`
    `echo -e "${RED}❌${NC} Database connection: FAILED"`
`fi`
`echo ""`

# `Calculate restoration time`
`END_TIME=$(date +%s)`
`ELAPSED=$((END_TIME - START_TIME))`
`MINUTES=$((ELAPSED / 60))`
`SECONDS=$((ELAPSED % 60))`

`echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"`
`echo -e "${GREEN}║          Restoration Complete! ✓                       ║${NC}"`
`echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"`
`echo ""`
`echo -e "Restoration time: ${GREEN}${MINUTES}m ${SECONDS}s${NC}"`
`echo ""`
`echo "Next Steps:"`
`echo "1. Access Mautic web interface"`
`echo "2. Verify data integrity"`
`echo "3. Check container logs: docker-compose logs -f"`
`echo ""`
`echo -e "${YELLOW}Note: Cron container may still hang on email validation (known issue)${NC}"`
`echo ""`