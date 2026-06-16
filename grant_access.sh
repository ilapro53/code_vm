#!/bin/bash
# Использование:
#   grant_access 'E:\path\to\folder'          -> /workspace/mnt/e/path/to/folder
#   grant_access 'E:\path\to\folder' alias    -> /workspace/mnt/alias

WINDOWS_PATH="$1"
ALIAS="$2"

if [ -z "$WINDOWS_PATH" ]; then
    echo "Использование: grant_access <windows_path> [alias]"
    exit 1
fi

DRIVE=$(echo "$WINDOWS_PATH" | head -c1 | tr 'A-Z' 'a-z')
REST=$(echo "$WINDOWS_PATH" | cut -c3- | sed 's/\\/\//g')
HOST_PATH="/host_mnt/${DRIVE}${REST}"
HOST_PATH="${HOST_PATH%/}"

if [ ! -d "$HOST_PATH" ] && [ ! -f "$HOST_PATH" ]; then
    echo "Ошибка: $HOST_PATH не существует (из $WINDOWS_PATH)"
    echo "Проверь, что диск ${DRIVE^^}: добавлен в docker-compose.yml"
    exit 1
fi

if [ -n "$ALIAS" ]; then
    MOUNT_POINT="/workspace/mnt/$ALIAS"
else
    MOUNT_POINT="/workspace/mnt/${DRIVE}${REST}"
    MOUNT_POINT="${MOUNT_POINT%/}"
fi

if [ -L "$MOUNT_POINT" ]; then
    TARGET=$(readlink "$MOUNT_POINT")
    if [ "$TARGET" = "$HOST_PATH" ]; then
        echo "Уже есть: $MOUNT_POINT -> $HOST_PATH"
        exit 0
    fi
fi

mkdir -p "$(dirname "$MOUNT_POINT")"
ln -sf "$HOST_PATH" "$MOUNT_POINT"

if [ -z "$RESTORING" ]; then
    GRANT_LIST="/workspace/.grant_data/grant_list"
    mkdir -p /workspace/.grant_data
    chmod 755 /workspace/.grant_data
    already_exists=false
    if [ -f "$GRANT_LIST" ]; then
        while IFS='|' read -r lp_path lp_alias; do
            if [ "$lp_path" = "$WINDOWS_PATH" ]; then
                already_exists=true
                break
            fi
        done < "$GRANT_LIST"
    fi
    if [ "$already_exists" = false ]; then
        echo "$WINDOWS_PATH|$ALIAS" >> "$GRANT_LIST"
        chmod 644 "$GRANT_LIST"
    fi
fi

echo "Доступ выдан: $WINDOWS_PATH"
echo "  Контейнер: $MOUNT_POINT -> $HOST_PATH"
