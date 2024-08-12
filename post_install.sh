#!/bin/sh

set -xeu

# Load environment variable from /etc/iocage-env
. load_env

# Generate some configuration from templates.
sync_configuration

# Generate self-signed TLS certificates
if [ "${ALLOW_INSECURE_ACCESS:-true}" = "false" ]
then
	generate_self_signed_tls_certificates
fi

# Enable the necessary services
sysrc -f /etc/rc.conf nginx_enable="YES"
sysrc -f /etc/rc.conf mysql_enable="YES"
sysrc -f /etc/rc.conf php_fpm_enable="YES"
sysrc -f /etc/rc.conf redis_enable="YES"
sysrc -f /etc/rc.conf fail2ban_enable="YES"

# Start the service
service nginx start #2>/dev/null
service php-fpm start #2>/dev/null
service mysql-server start #2> /dev/null
service redis start #2>/dev/null

# https://docs.nextcloud.com/server/13/admin_manual/installation/installation_wizard.html do not use the same name for user and db
USER="dbadmin"
DB="nextcloud"
NCUSER="ncadmin"

# Save the config values
echo "$DB" > /root/dbname
echo "$USER" > /root/dbuser
echo "$NCUSER" > /root/ncuser
export LC_ALL=C
openssl rand --hex 8 > /root/dbpassword
openssl rand --hex 8 > /root/ncpassword
PASS=$(cat /root/dbpassword)
NCPASS=$(cat /root/ncpassword)

# Configure mysql
mysqladmin -u root password "${PASS}"
mysql -u root -p"${PASS}" --connect-expired-password <<-EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password USING PASSWORD('${PASS}');
CREATE USER '${USER}'@'localhost' IDENTIFIED WITH mysql_native_password USING PASSWORD('${PASS}');
GRANT ALL PRIVILEGES ON *.* TO '${USER}'@'localhost' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON ${DB}.* TO '${USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

# Make the default log directory
mkdir /var/log/zm
chown www:www /var/log/zm

# Use occ to complete Nextcloud installation
su -m www -c "php /usr/local/www/nextcloud/occ maintenance:install \
  --database=\"mysql\" \
  --database-name=\"nextcloud\" \
  --database-user=\"$USER\" \
  --database-pass=\"$PASS\" \
  --database-host=\"127.0.0.1\" \
  --admin-user=\"$NCUSER\" \
  --admin-pass=\"$NCPASS\" \
  --data-dir=\"/usr/local/www/nextcloud/data\""

su -m www -c "php /usr/local/www/nextcloud/occ background:cron"

su -m www -c "php /usr/local/www/nextcloud/occ config:system:set trusted_domains 1 --value='${IOCAGE_HOST_SUBNET}.*'"

su -m www -c "php /usr/local/www/nextcloud/occ app:install contacts"
su -m www -c "php /usr/local/www/nextcloud/occ app:install calendar"
su -m www -c "php /usr/local/www/nextcloud/occ app:install notes"
su -m www -c "php /usr/local/www/nextcloud/occ app:install deck"
su -m www -c "php /usr/local/www/nextcloud/occ app:install spreed"
su -m www -c "php /usr/local/www/nextcloud/occ app:install mail"

# create sessions tmp dir outside nextcloud installation
mkdir -p /usr/local/www/nextcloud-sessions-tmp >/dev/null 2>/dev/null
chmod o-rwx /usr/local/www/nextcloud-sessions-tmp
chown -R www:www /usr/local/www/nextcloud-sessions-tmp
chown -R www:www /usr/local/www/nextcloud/apps-pkg

# Starting fail2ban
service fail2ban start 2>/dev/null

# Removing rwx permission on the nextcloud folder to others users
chmod -R o-rwx /usr/local/www/nextcloud
# Give full ownership of the nextcloud directory to www
chown -R www:www /usr/local/www/nextcloud

echo "Database Name: $DB" > /root/PLUGIN_INFO
echo "Database User: $USER" >> /root/PLUGIN_INFO
echo "Database Password: $PASS" >> /root/PLUGIN_INFO

echo "Nextcloud Admin User: $NCUSER" >> /root/PLUGIN_INFO
echo "Nextcloud Admin Password: $NCPASS" >> /root/PLUGIN_INFO
