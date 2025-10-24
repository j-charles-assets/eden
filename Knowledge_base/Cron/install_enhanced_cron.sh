#!/bin/bash
# Installation script for Force_1 Enhanced Email Quota Enforcer

echo "Installing Force_1 Enhanced Email Quota Enforcer..."

# 1. Copy script to server
echo "Copying enhanced script to server..."
scp email_quota_enforcer_enhanced.sh hetzner:/opt/mautic/cron/

# 2. Make executable
echo "Making script executable..."
ssh hetzner "chmod +x /opt/mautic/cron/email_quota_enforcer_enhanced.sh"

# 3. Add to existing cron (runs every 10 minutes)
echo "Adding to cron schedule..."
ssh hetzner "docker exec force_1_cron bash -c 'echo \"*/10 * * * * /opt/mautic/cron/email_quota_enforcer_enhanced.sh >> /var/log/mautic/enhanced_cron.log 2>&1\" | crontab -u www-data -'"

# 4. Verify installation
echo "Verifying cron installation..."
ssh hetzner "docker exec force_1_cron crontab -u www-data -l"

echo ""
echo "✅ Installation complete!"
echo ""
echo "📊 What's now running:"
echo "   • Mautic built-in: Segments/Campaigns (every 15min)"
echo "   • Enhanced script: Email quota + bounces + webhooks + imports + maintenance (every 10min)"
echo ""
echo "📋 Monitoring:"
echo "   • Email quota log: ssh hetzner \"docker exec force_1_cron tail -f /var/log/mautic/enhanced_cron.log\""
echo "   • Email count: ssh hetzner \"docker exec force_1_cron cat /var/log/mautic/email_count.log\""
echo ""
echo "🎯 Email limit: 3,800 per 24-hour period (enforced automatically)"