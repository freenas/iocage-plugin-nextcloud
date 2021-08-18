# iocage-plugin-nextcloud

Artifact file(s) for Nextcloud iocage plugin

## Technical details

- Nextcloud comme preloaded with the default Hub and Groupware bundles containing the following apps:
  - contacts
  - calendar
  - notes
  - deck
  - mail
  - talk
- Fail2ban is configured to ban users for 24h after 3 wrong connection attempt in a 12h time frame.
- Cron job are executed by the system
- An `occ` command alias is available to ease the use of the Nextcloud CLI in a csh shell
- Nextcloud make use of Redis and APCu for caching
- Database migrations needs to be regularly run after version updates.

```bash
occ --no-interaction db:add-missing-columns
occ --no-interaction db:add-missing-indices
occ --no-interaction db:add-missing-primary-keys
```

## Limitations

- The installation process generate some self-signed SSL certificates. If you do not want your user to see a warning in their browser you have to replace them with some valid certificates from Letsencrypt or other SSL certificates provider.

- When you update the Nextcloud plugin, you should be careful to not skip any major version and to alway update to the last minor version before that.
