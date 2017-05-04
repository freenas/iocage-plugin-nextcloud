#!/bin/sh

# Enable the service
sysrc -f /etc/rc.conf nginx_enable="YES"
sysrc -f /etc/rc.conf mysql_enable="YES"
sysrc -f /etc/rc.conf php_fpm_enable="YES"

cp /usr/local/etc/php.ini-production /usr/local/etc/php.ini

#cp /usr/local/share/mysql/my-small.cnf /var/db/mysql/my.cnf
if [ ! -d "/usr/local/www/nextcloud/tmp" ] ; then
  mkdir -p /usr/local/www/nextcloud/tmp
fi
chown -R www:www /usr/local/www/nextcloud/tmp

# Start the service
service nginx start 2>/dev/null
service php-fpm start 2>/dev/null
service mysql-server start 2>/dev/null

USER="nextcloud"
DB="nextcloud"

# Save the config values
echo "$DB" > /root/dbname
echo "$USER" > /root/dbuser
export LC_ALL=C
cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 16 | head -n 1 > /root/dbpassword
PASS=`cat /root/dbpassword`

echo "Database Name: $DB"
echo "Database User: $USER"
echo "Database Password: $PASS"

# Configure mysql
mysql -u root <<-EOF
UPDATE mysql.user SET Password=PASSWORD('${PASS}') WHERE User='root';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';

CREATE DATABASE ${DB} CHARACTER SET utf8;
CREATE USER '${USER}'@'localhost' IDENTIFIED BY '${PASS}';
GRANT ALL PRIVILEGES ON ${DB}.* TO '${USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

mkdir -p /usr/local/www/nextcloud/tmp >/dev/null 2>/dev/null
chmod o-rwx /usr/local/www/nextcloud/tmp

