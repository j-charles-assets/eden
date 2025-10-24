# Eden Marketing Stack Deployment Guide

## Prerequisites
- Hetzner server with Docker and Docker Compose
- SSH access to server
- Domain configured for email sending

## Deployment Steps

### 1. Server Preparation
```bash
# SSH to server
ssh hetzner

# Create directories
mkdir -p /root/backups
```

### 2. Deploy Stack
```bash
# Copy docker-compose file
scp docker-compose/eden-current.yml hetzner:/root/docker-compose.yml

# Deploy containers
ssh hetzner "cd /root && docker-compose up -d"
```

### 3. Verify Deployment
```bash
# Check container status
ssh hetzner "docker ps --filter name=eden"

# Test web interface
curl -I http://178.156.206.220:8080
```

### 4. Access System
- **URL**: http://178.156.206.220:8080
- **Username**: jamesRogers@jcharlesassets.com
- **Password**: Elem2025!

## Configuration Notes
- Database: 200K+ contacts pre-loaded
- Email: Google SMTP Relay (configuration in progress)
- Throttling: 3,888 emails/day maximum
- Network: Isolated bridge (10.12.0.0/16)