#!/bin/bash
# Использование:
#   revoke_access alias
#   revoke_access 'E:\path\to\folder'

ARG="$1"

if [ -z "$ARG" ]; then
    echo "Использование: revoke_access <alias или windows_path>"
    exit 1
fi

GRANT_LIST="/workspace/.grant_data/grant_list"
MOUNT_POINT=""

if [ -f "$GRANT_LIST" ]; then
    while IFS='|' read -r win_path alias; do
        if [ "$alias" = "$ARG" ]; then
            MOUNT_POINT="/workspace/mnt/$alias"
            break
        elif [ "$win_path" = "$ARG" ]; then
            if [ -n "$alias" ]; then
                MOUNT_POINT="/workspace/mnt/$alias"
            else
                DRIVE=$(echo "$win_path" | head -c1 | tr 'A-Z' 'a-z')
                REST=$(echo "$win_path" | cut -c3- | sed 's/\\/\//g')
                MOUNT_POINT="/workspace/mnt/${DRIVE}${REST}"
                MOUNT_POINT="${MOUNT_POINT%/}"
            fi
            break
        fi
    done < "$GRANT_LIST"
fi

if [ -z "$MOUNT_POINT" ]; then
    if [[ "$ARG" =~ ^[A-Za-z]: ]]; then
        DRIVE=$(echo "$ARG" | head -c1 | tr 'A-Z' 'a-z')
        REST=$(echo "$ARG" | cut -c3- | sed 's/\\/\//g')
        MOUNT_POINT="/workspace/mnt/${DRIVE}${REST}"
        MOUNT_POINT="${MOUNT_POINT%/}"
    else
        MOUNT_POINT="/workspace/mnt/$ARG"
    fi
fi

if [ ! -L "$MOUNT_POINT" ] && [ ! -e "$MOUNT_POINT" ]; then
    echo "Ошибка: $MOUNT_POINT не существует"
    exit 1
fi

rm -f "$MOUNT_POINT" 2>/dev/null

    if [ -f "$GRANT_LIST" ]; then
        while IFS='|' read -r win_path alias; do
            if [ "$win_path" = "$ARG" ] || [ "$alias" = "$ARG" ]; then
                continue
            fi
            echo "$win_path|$alias"
        done < "$GRANT_LIST" > "${GRANT_LIST}.tmp" 2>/dev/null || true
        mv "${GRANT_LIST}.tmp" "$GRANT_LIST"
        chmod 644 "$GRANT_LIST"
    fi

echo "Доступ закрыт: $ARG"
echo "  Был: $MOUNT_POINT"
