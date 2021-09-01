#!/bin/sh

set -eu

# Load environment variable from /etc/iocage-env
. /usr/local/bin/load_env

# Generate certificates if there is none
if [ ! -e /usr/local/etc/letsencrypt/live/truenas ]
then
	generate_self_signed_tls_certificates
	sysrc -f /etc/rc.conf redis_enable="YES"
	sysrc -f /etc/rc.conf fail2ban_enable="YES"
	service redis start 2>/dev/null
	service fail2ban start 2>/dev/null

	su -m www -c "php /usr/local/www/nextcloud/occ background:cron"
	su -m www -c "php /usr/local/www/nextcloud/occ app:install contacts"
	su -m www -c "php /usr/local/www/nextcloud/occ app:install calendar"
	su -m www -c "php /usr/local/www/nextcloud/occ app:install notes"
	su -m www -c "php /usr/local/www/nextcloud/occ app:install deck"
	su -m www -c "php /usr/local/www/nextcloud/occ app:install spreed"
	su -m www -c "php /usr/local/www/nextcloud/occ app:install mail"
fi

# Generate some configuration from templates.
/usr/local/bin/sync_configuration

# Removing rwx permission on the nextcloud folder to others users
chmod -R o-rwx /usr/local/www/nextcloud
# Give full ownership of the nextcloud directory to www
chown -R www:www /usr/local/www/nextcloud
