#!/bin/bash

echo "CHANGING ROOT PASSWORD" > /dev/kmsg
echo "root:XXXXX" | chpasswd
pwconv
cp /etc/passwd /usr/config/backupconfig/etc/passwd
cp /etc/shadow /usr/config/backupconfig/etc/shadow

