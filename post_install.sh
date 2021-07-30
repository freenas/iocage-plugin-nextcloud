#!/bin/sh

set -eu

# Enable the necessary services
sysrc -f /etc/rc.conf nginx_enable="YES"
sysrc -f /etc/rc.conf mysql_enable="YES"
sysrc -f /etc/rc.conf php_fpm_enable="YES"
sysrc -f /etc/rc.conf redis_enable="YES"

# Start the service
service nginx start 2>/dev/null
service php-fpm start 2>/dev/null
service mysql-server start 2>/dev/null
service redis start 2>/dev/null

# https://docs.nextcloud.com/server/13/admin_manual/installation/installation_wizard.html do not use the same name for user and db
USER="dbadmin"
DB="nextcloud"
NCUSER="ncadmin"

# Save the config values
echo "$DB" > /root/dbname
echo "$USER" > /root/dbuser
echo "$NCUSER" > /root/ncuser
export LC_ALL=C
cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1 > /root/dbpassword
cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1 > /root/ncpassword
PASS=$(cat /root/dbpassword)
NCPASS=$(cat /root/ncpassword)

# Configure mysql
mysqladmin -u root password "${PASS}"
mysql -u root -p"${PASS}" --connect-expired-password <<-EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${PASS}';
CREATE USER '${USER}'@'localhost' IDENTIFIED WITH mysql_native_password BY '${PASS}';
GRANT ALL PRIVILEGES ON *.* TO '${USER}'@'localhost' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON ${DB}.* TO '${USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

# Make the default log directory
mkdir /var/log/zm
chown www:www /var/log/zm

# If on NAT, we need to use the HOST address as the IP
if [ -e "/etc/iocage-env" ] ; then
	IOCAGE_PLUGIN_IP=$(cat /etc/iocage-env | grep HOST_ADDRESS= | cut -d '=' -f 2)
	echo "Using NAT Address: $IOCAGE_PLUGIN_IP"
fi

mv /root/truenas.config.php /usr/local/www/nextcloud/config/truenas.config.php
chown -R www:www /usr/local/www/nextcloud/config
chmod -R u+rw /usr/local/www/nextcloud/config

# Use occ to complete Nextcloud installation
su -m www -c "php /usr/local/www/nextcloud/occ maintenance:install \
  --database=\"mysql\" \
  --database-name=\"nextcloud\" \
  --database-user=\"$USER\" \
  --database-pass=\"$PASS\" \
  --database-host=\"localhost\" \
  --admin-user=\"$NCUSER\" \
  --admin-pass=\"$NCPASS\" \
  --data-dir=\"/usr/local/www/nextcloud/data\""

# TODO: No domain name ?
su -m www -c "php /usr/local/www/nextcloud/occ config:system:set trusted_domains 1 --value='${IOCAGE_PLUGIN_IP}'"

# Enable caching
# su -m www -c 'php /usr/local/www/nextcloud/occ config:system:set memcache.local --value="\\OC\\Memcache\\APCu"'
su -m www -c 'php /usr/local/www/nextcloud/occ config:system:set redis host --value="localhost"'
su -m www -c 'php /usr/local/www/nextcloud/occ config:system:set memcache.distributed --value="\\OC\\Memcache\\Redis"'
su -m www -c 'php /usr/local/www/nextcloud/occ config:system:set memcache.locking --value="\\OC\\Memcache\\Redis"'

# workaround for occ (in shell just use occ instead of su -m www -c "....")
echo >> .cshrc
echo alias occ ~/occ.sh >> .cshrc
echo 'su -m www -c php\ ``/usr/local/www/nextcloud/occ\ "$*"``' > ~/occ.sh
chmod u+x ~/occ.sh

# create sessions tmp dir outside nextcloud installation
mkdir -p /usr/local/www/nextcloud-sessions-tmp >/dev/null 2>/dev/null
chmod o-rwx /usr/local/www/nextcloud-sessions-tmp
chown -R www:www /usr/local/www/nextcloud-sessions-tmp
chown -R www:www /usr/local/www/nextcloud/apps-pkg

# Removing rwx permission on the nextcloud folder to others users
chmod -R o-rwx /usr/local/www/nextcloud

# Give full ownership of the nextcloud directory to www
chown -R www:www /usr/local/www/nextcloud

echo "Database Name: $DB" > /root/PLUGIN_INFO
echo "Database User: $USER" >> /root/PLUGIN_INFO
echo "Database Password: $PASS" >> /root/PLUGIN_INFO

echo "Nextcloud Admin User: $NCUSER" >> /root/PLUGIN_INFO
echo "Nextcloud Admin Password: $NCPASS" >> /root/PLUGIN_INFO
