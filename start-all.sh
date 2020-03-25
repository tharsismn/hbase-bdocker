#!/bin/bash

set -e
echo "starting sshd..."
/usr/sbin/sshd -D &

echo "starting hbase..."
start-hbase.sh

exec "$@"
