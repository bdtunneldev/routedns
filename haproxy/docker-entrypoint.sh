#!/bin/sh
set -e

CONFIG_TEMPLATE="/usr/local/etc/haproxy/haproxy.cfg"
CONFIG_FILE="/tmp/haproxy.cfg"

# Substitute environment variables in config


# Start HAProxy with the processed config
exec haproxy -f "$CONFIG_FILE" "$@"
