#!/bin/sh

# Enable the service
sysrc -f /etc/rc.conf nginx_enable="YES"
sysrc -f /etc/rc.conf mysql_enable="YES"
sysrc -f /etc/rc.conf php_fpm_enable="YES"

cp /usr/local/etc/php.ini-production /usr/local/etc/php.ini
# Modify opcache settings in php.ini according to Nextcloud documentation (remove comment and set recommended value)
# https://docs.nextcloud.com/server/15/admin_manual/configuration_server/server_tuning.html#enable-php-opcache
sed -i '' 's/.*opcache.enable=.*/opcache.enable=1/' /usr/local/etc/php.ini
sed -i '' 's/.*opcache.enable_cli=.*/opcache.enable_cli=1/' /usr/local/etc/php.ini
sed -i '' 's/.*opcache.interned_strings_buffer=.*/opcache.interned_strings_buffer=8/' /usr/local/etc/php.ini
sed -i '' 's/.*opcache.max_accelerated_files=.*/opcache.max_accelerated_files=10000/' /usr/local/etc/php.ini
sed -i '' 's/.*opcache.memory_consumption=.*/opcache.memory_consumption=128/' /usr/local/etc/php.ini
sed -i '' 's/.*opcache.save_comments=.*/opcache.save_comments=1/' /usr/local/etc/php.ini
sed -i '' 's/.*opcache.revalidate_freq=.*/opcache.revalidate_freq=1/' /usr/local/etc/php.ini
# recommended value of 512MB for php memory limit (avoid warning when running occ)
sed -i '' 's/.*memory_limit.*/memory_limit=512M/' /usr/local/etc/php.ini
# recommended value of 10 (instead of 5) to avoid timeout
sed -i '' 's/.*pm.max_children.*/pm.max_children=10/' /usr/local/etc/php-fpm.d/nextcloud.conf
# Nextcloud wants PATH environment variable set.  Use the same
# environment variables found in the 'www' php-fpm configuration for
# Nextcloud.
if [ -e /usr/local/etc/php-fpm.d/www.conf ] ; then
    cat /usr/local/etc/php-fpm.d/www.conf |
        grep "^env\[" >> /usr/local/etc/php-fpm.d/nextcloud.conf
fi

# Start the service
service nginx start 2>/dev/null
service php-fpm start 2>/dev/null
service mysql-server start 2>/dev/null

#https://docs.nextcloud.com/server/13/admin_manual/installation/installation_wizard.html do not use the same name for user and db
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
PASS=`cat /root/dbpassword`
NCPASS=`cat /root/ncpassword`

if [ -e "/root/.mysql_secret" ] ; then
   # Mysql > 57 sets a default PW on root
   TMPPW=$(cat /root/.mysql_secret | grep -v "^#")
   echo "SQL Temp Password: $TMPPW"

# Configure mysql
mysql -u root -p"${TMPPW}" --connect-expired-password <<-EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${PASS}';
CREATE USER '${USER}'@'localhost' IDENTIFIED BY '${PASS}';
GRANT ALL PRIVILEGES ON *.* TO '${USER}'@'localhost' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON ${DB}.* TO '${USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

# Make the default log directory
mkdir /var/log/zm
chown www:www /var/log/zm

else
   # Mysql <= 56 does not

# Configure mysql
mysql -u root <<-EOF
UPDATE mysql.user SET Password=PASSWORD('${PASS}') WHERE User='root';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';

CREATE USER '${USER}'@'localhost' IDENTIFIED BY '${PASS}';
GRANT ALL PRIVILEGES ON *.* TO '${USER}'@'localhost' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON ${DB}.* TO '${USER}'@'localhost';
FLUSH PRIVILEGES;
EOF
fi

# If on NAT, we need to use the HOST address as the IP
if [ -e "/etc/iocage-env" ] ; then
	IOCAGE_PLUGIN_IP=$(cat /etc/iocage-env | grep HOST_ADDRESS= | cut -d '=' -f 2)
	echo "Using NAT Address: $IOCAGE_PLUGIN_IP"
fi

#Use occ to complete Nextcloud installation
su -m www -c "php /usr/local/www/nextcloud/occ maintenance:install --database=\"mysql\" --database-name=\"nextcloud\" --database-user=\"$USER\" --database-pass=\"$PASS\" --database-host=\"localhost\" --admin-user=\"$NCUSER\" --admin-pass=\"$NCPASS\" --data-dir=\"/usr/local/www/nextcloud/data\"" 
su -m www -c "php /usr/local/www/nextcloud/occ config:system:set trusted_domains 1 --value=\"${IOCAGE_PLUGIN_IP}\""

#workaround for occ (in shell just use occ instead of su -m www -c "....")
echo >> .cshrc
echo alias occ ./occ.sh >> .cshrc
echo 'su -m www -c php\ ``/usr/local/www/nextcloud/occ\ "$*"``' > ~/occ.sh
chmod u+x ~/occ.sh

#workaround for app-pkg
sed -i '' "s|false|true|g" /usr/local/www/nextcloud/config/config.php

# create sessions tmp dir outside nextcloud installation
mkdir -p /usr/local/www/nextcloud-sessions-tmp >/dev/null 2>/dev/null
chmod o-rwx /usr/local/www/nextcloud-sessions-tmp
chown -R www:www /usr/local/www/nextcloud-sessions-tmp

chmod -R o-rwx /usr/local/www/nextcloud

#updater needs this
chown -R www:www /usr/local/www/nextcloud

#restart the services to make sure we have pick up the new permission
service php-fpm restart 2>/dev/null
#nginx restarts to fast while php is not fully started yet
sleep 5
service nginx restart 2>/dev/null

echo "Database Name: $DB" > /root/PLUGIN_INFO
echo "Database User: $USER" >> /root/PLUGIN_INFO
echo "Database Password: $PASS" >> /root/PLUGIN_INFO

echo "Nextcloud Admin User: $NCUSER" >> /root/PLUGIN_INFO
echo "Nextcloud Admin Password: $NCPASS" >> /root/PLUGIN_INFO
