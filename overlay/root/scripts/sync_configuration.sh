#!/bin/sh

set -eu

. /root/scripts/load_env.sh

# Generate nginx configuration from the base template
envsubst "\${IOCAGE_HOST_PORT}" < "/usr/local/etc/nginx/conf.d/nextcloud.conf.template" > "/usr/local/etc/nginx/conf.d/nextcloud.conf"

# Copy Nextcloud custom configuration
cp /root/config/truenas.config.php /usr/local/www/nextcloud/config/truenas.config.php
chown -R www:www /usr/local/www/nextcloud/config
chmod -R u+rw /usr/local/www/nextcloud/config

# Set cron job
crontab -u www /root/config/nextcloud.cron
