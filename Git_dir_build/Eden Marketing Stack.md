# Eden Marketing Stack

**Mautic 6.0.6 Email Marketing System**  
**Status:** 🟡 Operational (3/4 containers working, cron needs SMTP fix)  
**Contact Database:** 200,000 contacts intact  
**Last Backup:** 2025-10-22 23:14:19 (519MB)

---

## 🚨 EMERGENCY PROCEDURES

### System Down? Restore Immediately:
```bash
cd /root/
bash _eden\ restore/restore_eden_emergency.sh
```
**Restoration Time:** <2 minutes  
**Restores To:** Last known-good state with all 200K contacts

**Full Documentation:** [`_eden restore/Eden Emergency Restore Script.md`](_eden%20restore/Eden%20Emergency%20Restore%20Script.md)

### Backup Before Making Changes:
```bash
cd /root/
bash scripts/backup_eden.sh
```

**Full Documentation:** [`Git_dir_build/Eden Automated Backup Script.md`](Git_dir_build/Eden%20Automated%20Backup%20Script.md)

---

## 📊 CURRENT SYSTEM STATE

### Working Components ✅
- **Web UI:** Accessible at configured domain
- **Database:** 200K contacts intact, all data preserved
- **Worker:** Processing background jobs
- **Redis:** Caching operational
- **Docker Volumes:** Configuration and media files intact

### Known Issues 🔧
- **Cron Container:** Hanging on email validation check
- **Root Cause:** 4 Google SMTP relay configuration mismatches
- **Underlying Cause:** DNS propagation storm from SiteGround record changes

**CRITICAL FORENSIC ANALYSIS:** [`_eden restore/the cron solve.md`](_eden%20restore/the%20cron%20solve.md)  
*This document contains the complete cascade failure analysis - READ THIS BEFORE MAKING ANY CHANGES*

---

## 🎯 THE 4 SMTP CONFIGURATION ISSUES

**Full Troubleshooting Guide:** [`_eden restore/google-smtp-authentication-issues.md`](_eden%20restore/google-smtp-authentication-issues.md)  
**DNS Cascade Analysis:** [`_eden restore/the cron solve.md`](_eden%20restore/the%20cron%20solve.md)

### Issue 0: DNS Propagation Storm (THE ACTUAL ROOT CAUSE)
- **Problem:** Multiple conflicting DNS records at SiteGround
- **Postal DKIM:** `postal-boj0yn._domainkey.jcharlesassets.com`
- **Google DKIM:** `google._domainkey.jcharlesassets.com`
- **SPF Conflicts:** Multiple `v=spf1` records creating validation chaos
- **Impact:** All SSL/TLS handshakes failing, services unable to validate
- **Fix Required:** **DELETE ALL POSTAL DNS RECORDS FIRST**
  - Remove `postal-boj0yn._domainkey`
  - Remove `spf.postal.jcharlesassets.com`
  - Remove any other `postal.*` subdomains
  - Replace with single clean SPF: `v=spf1 include:_spf.google.com ip4:178.156.206.220 ~all`

### Issue 1: Authentication Mismatch
- **Google Config:** IP-based authentication only (no SMTP auth required)
- **Mautic Config:** Attempting to authenticate with empty credentials
- **Impact:** Authentication rejection loop
- **Fix Required:** Update MAILER_DSN to skip authentication

### Issue 2: IPv6/IPv4 Connection
- **Google Whitelist:** 178.156.206.220 (IPv4) and 2a01:4ff:f0:3c5c::1 (IPv6)
- **Container Behavior:** May default to IPv6 connection
- **Impact:** Connection attempts from wrong IP protocol
- **Fix Required:** Force IPv4 connection to smtp-relay.gmail.com

### Issue 3: TLS/Encryption Enforcement
- **Google Requirement:** "Require TLS encryption" = ON (mandatory)
- **Mautic DSN:** smtp://smtp-relay.gmail.com:587 (no explicit TLS)
- **Impact:** Unencrypted connection rejected
- **Fix Required:** Explicitly enforce TLS in DSN

### Issue 4: Domain Verification
- **Google Setting:** "Only addresses in my domains"
- **Mautic Sender:** newsletter@jcharlesassets.com
- **Status:** ⚠️ Requires verification that domain is in Google Workspace
- **Fix Required:** Confirm domain verification in Google Workspace Admin Console

---

## 🏗️ SYSTEM ARCHITECTURE

### Container Stack
```
eden_web       → Mautic web interface
eden_worker    → Background job processing
eden_cron      → Scheduled tasks & email sending (CURRENTLY HANGING)
eden_db        → MySQL database (200K contacts)
eden_redis     → Cache layer
```

### Data Locations
- **Project Root:** `/root/`
- **Docker Compose:** `/root/docker-compose.yml`
- **Production Config:** [`_eden restore/eden_mautic_complete.yml`](_eden%20restore/eden_mautic_complete.yml)
- **Backups:** `/root/backups/eden_backup_YYYYMMDD_HHMMSS/`
- **Volumes:** Docker managed (eden_config, eden_logs, eden_data, eden_db)

### Database Credentials
```
Host: eden_db
Database: eden
User: eden
Password: Elem2025!
```
**⚠️ Security Note:** Credentials are hardcoded in docker-compose.yml

---

## 📚 KNOWLEDGE BASE

### Quick Reference by Category

#### 🔧 **Emergency Recovery**
- [`_eden restore/backup_strategy.md`](_eden%20restore/backup_strategy.md) - Complete backup/restore methodology
- [`_eden restore/Eden Emergency Restore Script.md`](_eden%20restore/Eden%20Emergency%20Restore%20Script.md) - Recovery procedures
- [`_eden restore/deployment-guide.md`](_eden%20restore/deployment-guide.md) - Fresh deployment steps

#### 📧 **Email Configuration**
- [`_eden restore/google-smtp-authentication-issues.md`](_eden%20restore/google-smtp-authentication-issues.md) - SMTP troubleshooting
- [`_eden restore/the cron solve.md`](_eden%20restore/the%20cron%20solve.md) - DNS/Email cascade analysis
- [`Knowledge_base/Expert Analysis and Resolution...md`](Knowledge_base/Expert%20Analysis%20and%20Resolution%20of%20Google%20Workspace%20SMTP%20Relay%20Configuration%20Conflict%20in%20Postal.md) - Comprehensive SMTP guide

#### ⚙️ **Cron Management**
- [`Knowledge_base/Cron/cron.md`](Knowledge_base/Cron/cron.md) - Cron configuration docs
- [`Knowledge_base/Cron/install_enhanced_cron.sh`](Knowledge_base/Cron/install_enhanced_cron.sh) - Cron installation
- [`Knowledge_base/Cron/email_quota_enforcer_enhanced.sh`](Knowledge_base/Cron/email_quota_enforcer_enhanced.sh) - Email quota management
- [`Knowledge_base/Cron/mautic_cron_force1.sh`](Knowledge_base/Cron/mautic_cron_force1.sh) - Mautic cron jobs

#### 🎨 **Email Templates**
- [`Knowledge_base/email_templates/jays_template_email.html`](Knowledge_base/email_templates/jays_template_email.html)
- [`Knowledge_base/email_templates/terraboost-email-template.html`](Knowledge_base/email_templates/terraboost-email-template.html)

#### 🔍 **System Analysis**
- [`Knowledge_base/FORCE_1_TECHNICAL_DEEP_DIVE.md`](Knowledge_base/FORCE_1_TECHNICAL_DEEP_DIVE.md) - Complete Force_1 analysis
- [`Knowledge_base/U-Green.md`](Knowledge_base/U-Green.md) - U-Green project documentation

#### ⚙️ **Configuration Files**
- [`Knowledge_base/php/mautic_local_legacy_fixed.php`](Knowledge_base/php/mautic_local_legacy_fixed.php) - Working config
- [`Knowledge_base/php/mautic_local_legacy.php`](Knowledge_base/php/mautic_local_legacy.php) - Legacy config
- [`Knowledge_base/Postal/Caddyfile.fixed`](Knowledge_base/Postal/Caddyfile.fixed) - Reverse proxy config

---

## ⚠️ THE FORCE_1 CASCADE FAILURE (Critical Context)

**FULL FORENSIC TIMELINE:** [`_eden restore/the cron solve.md`](_eden%20restore/the%20cron%20solve.md)

### The Cascade Sequence:

**~Oct 12-13, 2025:** Archon agents service crashes
- Multiple SPF record changes at SiteGround
- DNS propagation storm begins
- SSL/TLS handshakes start failing across services

**Oct 21-22, 2025:** Force_1 Google SMTP configuration change
1. Changed email config in Mautic UI (Postal → Google SMTP)
2. Hit "Save"
3. Mautic attempted DNS validation via unstable SiteGround DNS
4. DNS had conflicting SPF records (Postal vs Google)
5. Validation failed → Mautic corrupted/erased `local.php`
6. Container mismatch caused system-wide cascade
7. Entire Force_1 system shattered

**Oct 23, 2025:** Eden restoration
- Archon discovered down for 10+ days
- DNS infrastructure unstable throughout
- Eden deployed with lessons learned

### Root Causes Identified:

1. **DNS Propagation Storm**
   - Constant changes to SiteGround DNS records
   - Inconsistent responses from different DNS servers
   - SSL certificate validation failures

2. **Conflicting Email Infrastructure**
   - Postal DKIM: `postal-boj0yn._domainkey`
   - Google DKIM: `google._domainkey`
   - Multiple SPF records creating authentication confusion

3. **UI vs Container Mismatch**
   - Mautic UI showed: `localhost:25`
   - Container had: `smtp-relay.gmail.com:587`
   - Validation attempted wrong endpoint

4. **The Critical Mistake**
   - Changed UI configuration while containers expected different setup
   - No pre-flight testing of new configuration
   - No backup before major change

### Lesson Learned:

**NEVER change Mautic UI email settings without:**
1. Creating fresh backup first
2. Fixing container configuration to match
3. Testing containers in isolation
4. Ensuring DNS is stable (no recent changes)
5. Having emergency restore script ready

**The Pattern:** Container config → Test → UI config → Commit
**NOT:** UI config → Container breaks → System shatters

---

## 🚀 QUICK START (Fresh Deployment)

**Full Guide:** [`_eden restore/deployment-guide.md`](_eden%20restore/deployment-guide.md)

### Prerequisites
- Docker & Docker Compose installed
- Google Workspace SMTP relay configured
- Domain DNS configured

### Deployment Steps
```bash
# Clone repository
git clone https://github.com/j-charles-assets/eden.git
cd eden

# Copy production config
cp "_eden restore/eden_mautic_complete.yml" docker-compose.yml

# Review configuration
cat docker-compose.yml

# Start services
docker-compose up -d

# Monitor startup
docker-compose logs -f
```

---

## 🔧 MAINTENANCE PROCEDURES

### Create Backup
```bash
cd /root/
bash scripts/backup_eden.sh
```
Creates timestamped backup in `/root/backups/`

**Documentation:** [`Git_dir_build/Eden Automated Backup Script.md`](Git_dir_build/Eden%20Automated%20Backup%20Script.md)

### Restore from Backup
```bash
cd /root/
bash _eden\ restore/restore_eden_emergency.sh
```
Restores to last backup state in <2 minutes

**Documentation:** [`_eden restore/Eden Emergency Restore Script.md`](_eden%20restore/Eden%20Emergency%20Restore%20Script.md)

### View Container Logs
```bash
docker-compose logs -f eden_cron   # Watch cron container
docker-compose logs eden_web       # Check web interface
```

### Restart Services
```bash
docker-compose restart             # Restart all containers
docker-compose restart eden_cron   # Restart specific container
```

---

## 📝 MAKING CONFIGURATION CHANGES

### ⚠️ CRITICAL: The Safe Change Process

**Full Methodology:** [`_eden restore/backup_strategy.md`](_eden%20restore/backup_strategy.md)

1. **Create Backup First**
   ```bash
   bash scripts/backup_eden.sh
   ```

2. **Update docker-compose.yml**
   - Make changes to container configuration
   - Commit changes to Git with detailed message

3. **Test Container Configuration**
   ```bash
   docker-compose up -d
   docker-compose logs -f
   ```

4. **Only After Containers Work: Update Mautic UI**
   - Make matching changes in web interface
   - Hit "Save" only when containers are ready

5. **If Anything Breaks:**
   ```bash
   bash _eden\ restore/restore_eden_emergency.sh
   ```

### Git Workflow
```bash
# Before changes
git add .
git commit -m "SAVEPOINT: Description of current state"
git tag v1.x-descriptive-name

# After successful changes
git add .
git commit -m "Fixed: Specific change with context"
git tag v1.x+1-new-feature
git push origin main --tags
```

---

## 📊 MONITORING & HEALTH CHECKS

### Container Status
```bash
docker ps                          # All containers
docker stats                       # Resource usage
docker-compose ps                  # Eden stack status
```

### Database Check
```bash
docker exec -it eden_db mysql -u eden -pElem2025! eden -e "SELECT COUNT(*) FROM leads;"
```
Should return: ~200,000

### Email Queue Status
```bash
docker exec -it eden_web php /var/www/html/bin/console mautic:emails:send
```

---

## 🔗 LINKS & RESOURCES

- **GitHub Repository:** https://github.com/j-charles-assets/eden
- **Mautic Documentation:** https://docs.mautic.org/
- **Google SMTP Relay:** https://support.google.com/a/answer/2956491

---

## 📞 SUPPORT & TROUBLESHOOTING

### Common Issues
1. **Cron Container Hanging:** See [`_eden restore/the cron solve.md`](_eden%20restore/the%20cron%20solve.md)
2. **Database Connection Failed:** Check credentials in docker-compose.yml
3. **UI Not Loading:** Check `docker-compose logs eden_web`
4. **SMTP Issues:** See [`_eden restore/google-smtp-authentication-issues.md`](_eden%20restore/google-smtp-authentication-issues.md)

### Debug Commands
```bash
# Check Mautic configuration
docker exec -it eden_web cat /var/www/html/config/local.php

# Test SMTP connection
docker exec -it eden_cron php /var/www/html/bin/console swiftmailer:spool:send -vvv

# Database connection test
docker exec -it eden_web php /var/www/html/bin/console doctrine:schema:validate
```

---

## 📁 REPOSITORY STRUCTURE

```
eden/
├── _eden restore/              # Emergency recovery & deployment
│   ├── .gitignore
│   ├── backup_strategy.md
│   ├── deployment-guide.md
│   ├── Eden Emergency Restore Script.md
│   ├── eden_mautic_complete.yml
│   ├── google-smtp-authentication-issues.md
│   └── the cron solve.md
│
├── Git_dir_build/              # Repository documentation
│   ├── Eden Automated Backup Script.md
│   ├── Eden Marketing Stack.md
│   └── README.md (this file)
│
└── Knowledge_base/             # Technical knowledge repository
    ├── Cron/                   # Cron management
    ├── email_templates/        # Email templates
    ├── php/                    # PHP configurations
    ├── Postal/                 # Postal configs
    ├── Expert Analysis...md
    ├── FORCE_1_TECHNICAL_DEEP_DIVE.md
    └── U-Green.md
```

---

## 📅 VERSION HISTORY

- **v1.0** (2025-10-22) - Eden baseline: 200K contacts, 3/4 containers working
- Future versions will be tagged as configurations are improved

---

**Last Updated:** 2025-10-23  
**Maintained By:** J Charles Assets  
**System Status:** Production with known SMTP issues pending fix