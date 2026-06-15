#!/bin/bash
set -e

mkdir -p /workspace/mnt
chmod 755 /workspace/mnt

# Закрыть прямой доступ к "сырым" дискам — только через grant_access
chown root:root /host_mnt
chmod 700 /host_mnt

# Одноразовая инициализация sandbox (если не создана)
SANDBOX=/home/aiuser/sandbox
if [ ! -d "$SANDBOX/etc" ]; then
    echo "Инициализация sandbox (одноразово, ~2-3 мин)..."
    fakeroot fakechroot debootstrap --variant=fakechroot bookworm \
        "$SANDBOX" http://deb.debian.org/debian/
    chown -R aiuser:aiuser "$SANDBOX"
    echo "Sandbox готов: $SANDBOX"
fi

exec gosu aiuser "$@"