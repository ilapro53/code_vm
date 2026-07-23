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
MATCHED=0

if [ -f "$GRANT_LIST" ]; then
    # Удалить symlink'и для всех подходящих entry
    while IFS='|' read -r win_path alias; do
        if [ "$alias" = "$ARG" ] || [ "$win_path" = "$ARG" ]; then
            if [ -n "$alias" ]; then
                MP="/workspace/mnt/$alias"
            else
                DRIVE=$(echo "$win_path" | head -c1 | tr 'A-Z' 'a-z')
                REST=$(echo "$win_path" | cut -c3- | sed 's/\\/\//g')
                MP="/workspace/mnt/${DRIVE}${REST}"
                MP="${MP%/}"
            fi
            rm -f "$MP" 2>/dev/null
            MATCHED=1
        fi
    done < "$GRANT_LIST"

    # Переписать grant_list без подходящих entry
    TMP="${GRANT_LIST}.tmp"
    : > "$TMP"
    while IFS='|' read -r win_path alias; do
        if [ "$win_path" != "$ARG" ] && [ "$alias" != "$ARG" ]; then
            echo "${win_path}|${alias}" >> "$TMP"
        fi
    done < "$GRANT_LIST"
    mv "$TMP" "$GRANT_LIST"
    chmod 644 "$GRANT_LIST"
fi

if [ "$MATCHED" -eq 0 ]; then
    # Fallback: вычислить MOUNT_POINT напрямую из ARG
    if [[ "$ARG" =~ ^[A-Za-z]: ]]; then
        DRIVE=$(echo "$ARG" | head -c1 | tr 'A-Z' 'a-z')
        REST=$(echo "$ARG" | cut -c3- | sed 's/\\/\//g')
        MP="/workspace/mnt/${DRIVE}${REST}"
        MP="${MP%/}"
    else
        MP="/workspace/mnt/$ARG"
    fi
    if [ ! -L "$MP" ] && [ ! -e "$MP" ]; then
        echo "Ошибка: $MP не существует"
        exit 1
    fi
    rm -f "$MP" 2>/dev/null
fi

echo "Доступ закрыт: $ARG"
