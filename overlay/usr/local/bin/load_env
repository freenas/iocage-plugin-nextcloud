#!/bin/sh

set -eu

export IOCAGE_NETWORKING_MODE
export IOCAGE_NAT_FORWARDS
export IOCAGE_HOST_PORT_HTTP
export IOCAGE_JAIL_PORT_HTTP
export IOCAGE_HOST_PORT_HTTPS
export IOCAGE_JAIL_PORT_HTTPS
export IOCAGE_HOST_ADDRESS
export IOCAGE_HOST_ADDRESS_BCAST

if [ -e "/etc/iocage-env" ]
then
	IOCAGE_NETWORKING_MODE=$(grep NETWORKING_MODE= /etc/iocage-env | cut -d '=' -f 2)

	if [ "$IOCAGE_NETWORKING_MODE" = "nat" ]
	then
		IOCAGE_NAT_FORWARDS=$(grep NAT_FORWARDS= /etc/iocage-env | cut -d '=' -f 2)
		IOCAGE_HOST_PORT_HTTP=$(echo "$IOCAGE_NAT_FORWARDS" | cut -d ',' -f1 | cut -d ':' -f2 | cut -d ')' -f1)
		IOCAGE_JAIL_PORT_HTTP=$(echo "$IOCAGE_NAT_FORWARDS" | cut -d ',' -f1 | cut -d ':' -f1 | cut -d '(' -f2)
		IOCAGE_HOST_PORT_HTTPS=$(echo "$IOCAGE_NAT_FORWARDS" | cut -d ',' -f2 | cut -d ':' -f2 | cut -d ')' -f1)
		IOCAGE_JAIL_PORT_HTTPS=$(echo "$IOCAGE_NAT_FORWARDS" | cut -d ',' -f2 | cut -d ':' -f1 | cut -d '(' -f2)
	else
		IOCAGE_HOST_PORT_HTTP=80
		IOCAGE_JAIL_PORT_HTTP=80
		IOCAGE_HOST_PORT_HTTPS=443
		IOCAGE_JAIL_PORT_HTTPS=443
	fi

	IOCAGE_HOST_ADDRESS=$(grep HOST_ADDRESS= /etc/iocage-env | cut -d '=' -f 2)
	IOCAGE_HOST_ADDRESS_BCAST=$(grep HOST_ADDRESS_BCAST= /etc/iocage-env | cut -d '=' -f 2)
fi
