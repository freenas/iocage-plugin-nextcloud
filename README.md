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

## User limit

This appliance is developed and maintained by Nextcloud GmbH and meant for private, or small business use. This is why the appliance is limited to 100 users. With more users comes a more critical role in organizations, for which we recommend Nextcloud Enterprise. The appliance can be upgraded to Nextcloud Enterprise. Contact Nextcloud for more information.

## TLS certificates

The installation process generate self-signed TLS certificates. If you do not want your users to see a warning in their browser, you either need to install the root CA in all your users devices, or you need to generate some valid certificates with Letsencrypt or other certificates provider.

Certificate validity time:

- Self-signed certificates are valid for two years. This is so not tech-savvy people do not have to go through the browser warning too frequently.
- Letsencrypt certificates are valid for 90 days and a cron task will try to renew it every week.

To generate valid certificates with Letsencrypt, first, make sure that TrueNAS is configured to proxy requests using your domain name to Nextcloud and that the Nextcloud jail is accessible through ports 80 and 443. You can then run the following commands to install valid certificates:

```bash
generate_letsencrypt_certificates <domain_name> <admin_email>
```

Then add your domain to Nextcloud known hosts in: `/usr/local/www/nextcloud/config/config.php`.

## Technical details

- Fail2ban is configured to ban users for 24h after 3 wrong connection attempt in a 12h time frame.
- Cron job are executed by the system.
- Nextcloud make use of Redis and APCu for caching.
- Database migrations needs to be regularly run after version updates. You can use the `run_db_migrations` command to run them.

## Updates

When you update the Nextcloud plugin, you should be careful to not skip any major version and to alway update to the last minor version before that.

## Scripts

- `generate_self_signed_certificates`:

This script will generate self-signed TLS certificates for you. It will place them here: `/usr/local/etc/letsencrypt/live/truenas`. It uses the letsencrypt directory so you do not have to touch the nginx configuration when switching to letsencrypt certificates. You can install the `root.cer` file into your devices and browsers to avoid the warning page when you access Nextcloud. If you run the command again, it will reuse the previous `root.cer` so you do not have to reinstall it.

- `generate_letsencrypt_certificates <domain_name> <admin_email>`:

This script will generate valid TLS certificates with Let's encrypt. See the "TLS certificates" section above for more information.

- `load_env`:

Load and export environment variables from `/etc/iocage-env`. You can add it at the begging of your script to easily access those variables.
This will also load the content of `/root/jail_options.env`.

Example of `/root/jail_options.env`:

```shell
# Allow insecure access to Nextcloud through HTTP. Useful when TrueNAS is behind an external proxy.
export ALLOW_INSECURE_ACCESS=<boolean> # default: true
```

- `occ [<occ command>]`:

This is alias to ease the use of the Nextcloud CLI in a csh shell.

- `renew_certificates`:

Script called by cron to renew either self-signed or letsencrypt-issued certificates.

- `run_db_migrations`:

Nextcloud sometime need to run some long migrations after an update. This script will help you to run them. Please run it when your server is in a low-usage time.

- `sync_configuration`:

Will generate configuration from templates or move other configuration to their final location.
