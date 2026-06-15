#!/bin/bash
# Одноразовая инициализация fakechroot sandbox
# Запускать от aiuser, занимает несколько минут
set -e

SANDBOX=~/sandbox
if [ -d "$SANDBOX/etc/debootstrap" ]; then
    echo "Sandbox уже создан: $SANDBOX"
    exit 0
fi

echo "Инициализация sandbox ($SANDBOX)..."
fakeroot fakechroot debootstrap --variant=fakechroot bookworm \
    "$SANDBOX" http://deb.debian.org/debian/

echo "Готово: $SANDBOX"
