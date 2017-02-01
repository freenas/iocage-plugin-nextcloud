#!/bin/sh

# Enable the service
sysrc -f /etc/rc.conf nginx_enable="YES"
sysrc -f /etc/rc.conf mysql_enable="YES"
sysrc -f /etc/rc.conf php_fpm_enable="YES"

cp /usr/local/etc/php.ini-production /usr/local/etc/php.ini

cp /usr/local/share/mysql/my-small.cnf /var/db/mysql/my.cnf

# Configure mysql
mysql -u root <<-EOF
UPDATE mysql.user SET Password=PASSWORD('nextcloud') WHERE User='root';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.db WHERE Db='test' OR Db='test_%';

CREATE DATABASE nextclouddb CHARACTER SET utf8;
CREATE USER 'nextclouduser'@'localhost' IDENTIFIED BY 'nextcloud';
GRANT ALL PRIVILEGES ON nextclouddb.* TO 'nextclouduser'@'localhost';
FLUSH PRIVILEGES;
EOF

mkdir -p /usr/local/www/nextcloud/tmp >/dev/null 2>/dev/null
chmod o-rwx /usr/local/www/nextcloud/tmp

# Start the service
service nginx start
service mysql-server start
service php-fpm start
