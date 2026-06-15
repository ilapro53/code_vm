#!/bin/bash
# Использование:
#   grant_access 'E:\path\to\folder'          → /workspace/mnt/e/path/to/folder
#   grant_access 'E:\path\to\folder' alias    → /workspace/mnt/alias

WINDOWS_PATH="$1"
ALIAS="$2"

if [ -z "$WINDOWS_PATH" ]; then
    echo "Использование: grant_access <windows_path> [alias]"
    exit 1
fi

DRIVE=$(echo "$WINDOWS_PATH" | head -c1 | tr 'A-Z' 'a-z')
REST=$(echo "$WINDOWS_PATH" | cut -c3- | sed 's/\\/\//g')
HOST_PATH="/host_mnt/${DRIVE}${REST}"

if [ ! -d "$HOST_PATH" ]; then
    echo "Ошибка: $HOST_PATH не существует (из $WINDOWS_PATH)"
    echo "Проверь, что диск ${DRIVE^^}: добавлен в docker-compose.yml"
    exit 1
fi

if [ -n "$ALIAS" ]; then
    MOUNT_POINT="/workspace/mnt/$ALIAS"
else
    MOUNT_POINT="/workspace/mnt/${DRIVE}${REST}"
fi

if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
    echo "Уже примонтировано: $MOUNT_POINT"
    # Сохранить в список (без дублей)
    GRANT_LIST="/root/.grant_list"
    if [ -f "$GRANT_LIST" ]; then
        grep -Fxq "$WINDOWS_PATH" "$GRANT_LIST" 2>/dev/null || echo "$WINDOWS_PATH" >> "$GRANT_LIST"
    else
        echo "$WINDOWS_PATH" > "$GRANT_LIST"
    fi
    exit 0
fi

mkdir -p "$MOUNT_POINT"
mount --bind "$HOST_PATH" "$MOUNT_POINT"

# Сохранить в список (без дублей)
GRANT_LIST="/root/.grant_list"
if [ -f "$GRANT_LIST" ]; then
    grep -Fxq "$WINDOWS_PATH" "$GRANT_LIST" 2>/dev/null || echo "$WINDOWS_PATH" >> "$GRANT_LIST"
else
    echo "$WINDOWS_PATH" > "$GRANT_LIST"
fi

echo "Доступ выдан: $WINDOWS_PATH"
echo "  Контейнер: $MOUNT_POINT"