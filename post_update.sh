#!/bin/sh

set -eu

# Load environment variable from /etc/iocage-env
. /root/scripts/load_env.sh

# Generate some configuration from templates.
/root/scripts/sync_configuration.sh
