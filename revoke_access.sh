#!/bin/bash
# Использование:
#   revoke_access alias
#   revoke_access 'E:\path\to\folder'

ARG="$1"

if [ -z "$ARG" ]; then
    echo "Использование: revoke_access <alias или windows_path>"
    exit 1
fi

if [[ "$ARG" =~ ^[A-Za-z]: ]]; then
    DRIVE=$(echo "$ARG" | head -c1 | tr 'A-Z' 'a-z')
    REST=$(echo "$ARG" | cut -c3- | sed 's/\\/\//g')
    MOUNT_POINT="/workspace/mnt/${DRIVE}${REST}"
else
    MOUNT_POINT="/workspace/mnt/$ARG"
fi

if ! mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
    echo "Ошибка: $MOUNT_POINT не примонтирован"
    exit 1
fi

umount "$MOUNT_POINT"
rmdir -p --ignore-fail-on-non-empty "$MOUNT_POINT" 2>/dev/null

# Удалить из списка grant по алиасу или пути
GRANT_LIST="/root/.grant_data/grant_list"
if [ -f "$GRANT_LIST" ]; then
    grep -Fxv "$ARG" "$GRANT_LIST" > "${GRANT_LIST}.tmp" 2>/dev/null || true
    mv "${GRANT_LIST}.tmp" "$GRANT_LIST"
fi

echo "Доступ закрыт: $ARG"
echo "  Был: $MOUNT_POINT"
