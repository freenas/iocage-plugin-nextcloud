#!/bin/sh

set -eu

# Generate certificates so nginx is happy
generate_self_signed_tls_certificates

# Enable and start new services
sysrc -f /etc/rc.conf redis_enable="YES"
sysrc -f /etc/rc.conf fail2ban_enable="YES"
service redis start 2>/dev/null
service fail2ban start 2>/dev/null
service mysql-server start 2> /dev/null

# Wait for mysql to be up
until mysql --user dbadmin --password="$(cat /root/dbpassword)" --execute "SHOW DATABASES" > /dev/null
do
    echo "MariaDB is unavailable - sleeping"
    sleep 1
done

# Change cron execution method
su -m www -c "php /usr/local/www/nextcloud/occ background:cron"

# Upgrade Nextcloud
su -m www -c "php /usr/local/www/nextcloud/occ upgrade"
