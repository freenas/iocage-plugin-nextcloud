# iocage-plugin-nextcloud

Artifact file(s) for Nextcloud iocage plugin

## New HTTPS requirement

One major change of the latest update is the switch to HTTPS. This means that all communications with Nextcloud will now be completely secure.
But for TrueNAS setups that uses NAT, admins will have to manually add a new port binding before upgrading Nextcloud.

- Stop the Nextcloud Plugin from the TrueNAS GUI
- Go to the "Jails" in the TrueNAS web GUI.
- Click on "Edit" for the Nextcloud Jail.
- Open the "Network Properties" tab.
- Add a new port binding at the bottom of the tab. The "Protocol" must be TCP, the "Jail Port Number" must be 443 and the "Host Port Number" can be any port that is free on your TrueNAS server.
- Restart the Nextcloud plugin.

Those steps can also be run after the upgrade, but you will need to run two commands so Nginx can take the change into account. Log into the Nextcloud plugin from the "Shell": `iocage console <nextcloud_plugin_name>`.

```bash
sync_configuration
service nginx restart
```

## Nextcloud Hub

Nextcloud comme preloaded with the default Hub and Groupware bundles containing the following applications:

- Contacts
- Calendar
- Notes
- Deck
- Mail
- Talk

## TLS certificates

The installation process generate self-signed TLS certificates. If you do not want your users to see a warning in their browser, you either need to install the root CA in all your users devices, or you need to generate some valid certificates with Letsencrypt or other certificates provider.

To generate valid certificates with Letsencrypt, first, make sure that TrueNAS is configured to proxy requests using your domain name to Nextcloud. Then, you can run the following commands to install valid certificates:

```bash
# Remove self-signed certificates
rm -rf /usr/local/etc/letsencrypt/truenas

# Ask letsencrypt for some certificates
certbot certonly \
    --rsa-key-size 4096 \
    --cert-name truenas \
    --non-interactive \
    --webroot \
    --webroot-path /usr/local/www/nextcloud \
    --force-renewal \
    --agree-tos \
    --email <your_email> \
    --domain <your_domain_name>

# Refresh nginx configuration to use 443 as HTTPS port
sync_configuration

# Restart nginx
service nginx restart
```

Then add your domain to Nextcloud known hosts in `/usr/local/www/nextcloud/config/config.php`.

## Technical details

- Fail2ban is configured to ban users for 24h after 3 wrong connection attempt in a 12h time frame.
- Cron job are executed by the system.
- Nextcloud make use of Redis and APCu for caching.
- Database migrations needs to be regularly run after version updates. You can use the `run_db_migrations` command to run them.

## Updates

When you update the Nextcloud plugin, you should be careful to not skip any major version and to alway update to the last minor version before that.


## Scripts

- `generate_self_signed_certificates`:

This script will generate TLS certificates for you. It will place them here: `/usr/local/etc/letsencrypt/live/truenas`. It uses the letsencrypt directory so you do not have to touch the nginx configuration when switching to letsencrypt certificates. You can install the `root.cer` file into your devices and browsers to avoid the warning page when you access Nextcloud. If you run the command again, it will reuse the previous `root.cer` so you do not have to reinstall it.

- `load_env`:

Load and export environment variables from `/etc/iocage-env`. You can add it at the begging of your script to easily access those variables.

- `occ`:

This is alias to ease the use of the Nextcloud CLI in a csh shell.

- `renew_certificates`:

Script called by cron to renew either self-signed or letsencrypt-issued certificates.

- `run_db_migrations`:

Nextcloud sometime need to run some long migrations after an update. This script will run them for you. Please run them when your server is in a low-usage time.

- `sync_configuration`:

Will generate configuration from templates or move other configuration to their final location.
