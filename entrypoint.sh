#!/bin/bash
set -e

mkdir -p /workspace/mnt
chmod 755 /workspace/mnt

# Закрыть прямой доступ к "сырым" дискам — только через grant_access
chown root:root /host_mnt
chmod 700 /host_mnt

# Восстановить grant-пути из списка
GRANT_DIR="/root/.grant_data"
GRANT_LIST="$GRANT_DIR/grant_list"
mkdir -p "$GRANT_DIR"
touch "$GRANT_LIST"
if [ -s "$GRANT_LIST" ]; then
    while IFS='|' read -r win_path alias; do
        [ -z "$win_path" ] && continue
        RESTORING=1 grant_access "$win_path" "$alias" || true
    done < "$GRANT_LIST"
fi

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