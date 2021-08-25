#!/bin/sh

set -eu

# Load environment variable from /etc/iocage-env
. /usr/local/bin/load_env

# Generate some configuration from templates.
/usr/local/bin/sync_configuration
