#!/bin/sh

set -eu

# Run migrations in /root/migrations.
if [ ! -e /root/migrations/current_migration.txt ]
then
	echo "0" > /root/migrations/current_migration.txt
fi

current_migration=$(cat /root/migrations/current_migration.txt)
while [ -f "/root/migrations/$((current_migration+1)).sh" ]
do
	echo "* [migrate] Migrating from $current_migration to $((current_migration+1))."

	{
		"/root/migrations/$((current_migration+1)).sh" &&
		current_migration=$((current_migration+1)) &&
		echo "* [migrate] Migration $current_migration done." &&
		echo "$current_migration" > /root/migrations/current_migration.txt
	} || {
		echo "ERROR - Fail to run migrations."
		# Do not exit so the post_update script can continue.
		break
	}
done

# Remove old files
rm -fv /usr/local/etc/php/php.truenas.ini
# Generate some configuration from templates.
sync_configuration

# Removing rwx permission on the nextcloud folder to others users
chmod -R o-rwx /usr/local/www/nextcloud
# Give full ownership of the nextcloud directory to www
chown -R www:www /usr/local/www/nextcloud

# DB migration check
run_db_migrations
