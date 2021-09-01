#!/bin/sh

set -eu

# Generate certificates so nginx is happy
generate_self_signed_tls_certificates

# Enable and start new services
sysrc -f /etc/rc.conf redis_enable="YES"
sysrc -f /etc/rc.conf fail2ban_enable="YES"
service redis start 2>/dev/null
service fail2ban start 2>/dev/null
service mysql-server start 2>/dev/null

# Change cron execution method
su -m www -c "php /usr/local/www/nextcloud/occ background:cron"

# Install default applications
su -m www -c "php /usr/local/www/nextcloud/occ app:install contacts"
su -m www -c "php /usr/local/www/nextcloud/occ app:install calendar"
su -m www -c "php /usr/local/www/nextcloud/occ app:install notes"
su -m www -c "php /usr/local/www/nextcloud/occ app:install deck"
su -m www -c "php /usr/local/www/nextcloud/occ app:install spreed"
su -m www -c "php /usr/local/www/nextcloud/occ app:install mail"
