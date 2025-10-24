# Google SMTP Authentication Issues - Eden Stack

**Status**: Active Investigation  
**Date**: 2025-10-23  
**System**: Eden Mautic Stack (200K+ contacts)  
**Issue**: Cron email sending failures with Google SMTP relay

## The Core Problem Pattern

### Force_1 Death Spiral:
1. **Containers configured for Postal**
2. **Changed UI to Google SMTP → Hit Save**
3. **UI instantly pushed config to containers**
4. **Containers weren't ready for Google config**
5. **BOOM - system shattered**

### Current Eden State:
- **Database has the "broken" Google SMTP config from Force_1**
- **Containers have some Google SMTP env vars, but not all 4 fixes**
- **Cron is hanging trying to validate this mismatched config**
- **You're terrified to hit "Save" in the UI (rightfully so!)**

## The Safe Path Forward

### Phase 1: Pre-Flight Container Configuration (Safe - No UI Changes)
Fix all 4 issues in `docker-compose.yml` BEFORE touching the UI:

#### 1. Authentication: No-Auth Mode
```yaml
MAILER_DSN: smtp://smtp-relay.gmail.com:587?verify_peer=0
# Or whatever the correct "skip auth" syntax is for Mautic 6.0.6
```

#### 2. Force IPv4 (avoid IPv6 confusion)
```yaml
# Add to cron container
extra_hosts:
  - "smtp-relay.gmail.com:178.156.206.220"
```

#### 3. Explicit TLS Enforcement
```yaml
# Ensure DSN includes TLS parameters
```

#### 4. Domain Verification Check
- Verify `jcharlesassets.com` is in Google Workspace domains list
- This is outside Docker - just confirmation

### Phase 2: Test Container Config (Still Safe)
1. **Restart containers with new compose file**
2. **Watch cron logs to see if validation completes**
3. **Don't touch the UI yet**

### Phase 3: UI Alignment (Only After Containers Work)
1. **Once cron stops hanging and containers are happy**
2. **Then make UI changes to match what containers expect**
3. **Hit Save with confidence**

## The Four Core Problems

### 1. Authentication Mismatch 🎯
**Google Configuration**: IP-based authentication (no SMTP user/pass required)  
**Mautic Behavior**: Trying to authenticate with empty credentials  
**Fix**: Configure Mautic DSN to skip authentication entirely

### 2. IPv4 vs IPv6 Confusion 🌐
**Google Whitelist Shows**:
- IPv4: `178.156.206.220` 
- IPv6: `2a01:4ff:f0:3c5c::1`

**Question**: Which IP is the cron container actually using to connect?  
**Fix**: Verify the outbound IP and ensure it matches Google's whitelist

### 3. TLS/Encryption Configuration 🔒
**Google Requirement**: TLS encryption (checked ✅)  
**Current Mautic DSN**: `smtp://smtp-relay.gmail.com:587`  
**Issue**: This might not be explicitly forcing TLS  
**Fix**: May need `smtps://` or explicit TLS parameters in the DSN

### 4. Domain Verification 📧
**Google Setting**: "Only addresses in my domains"  
**Mautic Sending From**: `newsletter@jcharlesassets.com`  
**Question**: Is `jcharlesassets.com` verified in Google Workspace?  
**Fix**: Verify domain ownership in Google Workspace

## Diagnostic Checklist

### What We Need to Check:
- [ ] What IP address does the `mautic_cron` container see when it tries to connect? (IPv4 vs IPv6)
- [ ] Is `jcharlesassets.com` listed and verified in your Google Workspace domains?
- [ ] What's the correct Mautic DSN format for IP-based auth with TLS on port 587?

### Investigation Commands:
```bash
# Check container outbound IP
ssh hetzner "docker exec eden_cron curl -s ifconfig.me"

# Check DNS resolution from container
ssh hetzner "docker exec eden_cron nslookup smtp-relay.gmail.com"

# Check current DSN configuration
ssh hetzner "docker exec eden_web env | grep MAILER_DSN"

# Check email logs for specific errors
ssh hetzner "docker logs eden_cron 2>&1 | grep -i smtp"
```

## Potential Solutions

### DSN Format Options:
```bash
# Current (problematic)
MAILER_DSN=smtp://smtp-relay.gmail.com:587

# Option 1: Force TLS
MAILER_DSN=smtp://smtp-relay.gmail.com:587?encryption=tls

# Option 2: Use SMTPS
MAILER_DSN=smtps://smtp-relay.gmail.com:587

# Option 3: Explicit no-auth TLS
MAILER_DSN=smtp://smtp-relay.gmail.com:587?encryption=tls&auth_mode=none
```

### Google Workspace Verification:
1. Login to Google Admin Console
2. Navigate to Apps → Google Workspace → Gmail
3. Check "Routing" settings for SMTP relay
4. Verify `jcharlesassets.com` is in allowed domains
5. Confirm IP whitelist includes server's actual outbound IP

## Next Steps

**Priority Order**:
1. **Verify outbound IP** - Ensure container uses whitelisted IP
2. **Check domain verification** - Confirm `jcharlesassets.com` in Google Workspace
3. **Test DSN formats** - Try explicit TLS/no-auth configurations
4. **Monitor logs** - Watch for specific SMTP error messages

**Success Criteria**:
- Cron emails send without authentication errors
- Google SMTP relay accepts connections from Eden stack
- Email delivery rate returns to normal levels