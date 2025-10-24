# Eden Backup & Recovery Strategy
**Created**: 2025-10-23
**Purpose**: Comprehensive backup system with chain of custody

## Current Working State (Baseline)
- **Date**: 2025-10-23 09:30 UTC
- **System**: Eden Mautic Stack
- **Status**: 95% Functional (cron issue with Google SMTP)
- **Contacts**: 200,004 contacts loaded
- **Backup Location**: `/root/backups/eden_backup_20251022_231419/`

## Git Configuration Management
### Tagged Configurations:
- `eden_mautic_complete.yml` - Current working docker-compose
- `force_1_production_ready.yml` - Previous attempt (broken)
- `force_1_clean_install.yml` - Clean install version

### Chain of Custody:
1. **v1.0-force1-broken**: Original Force_1 that broke on Google SMTP
2. **v2.0-eden-working**: Current Eden with 200K contacts (THIS VERSION)
3. **v3.0-eden-fixed**: Next version with Google SMTP working

## Snapshot Management
### Container Images:
- `eden_web:v2.0-working` - Web container with 200K contacts
- `eden_worker:v2.0-working` - Working message consumer
- `eden_db:v2.0-working` - Database with full contact data

### Volume Backups:
- `eden_config_backup_v2.0.tar.gz` - Configuration files
- `eden_database_v2.0.sql` - Complete database dump

## Recovery Procedures
### One-Command Restore:
```bash
./restore_eden_v2.0.sh
```

### Git Rollback:
```bash
git checkout v2.0-eden-working
docker-compose -f eden_mautic_complete.yml up -d
```

## Change Log
- **v2.0**: Eden deployment with 200K contacts, cron hanging on Google SMTP validation
- **v1.0**: Force_1 broken by Google SMTP configuration change