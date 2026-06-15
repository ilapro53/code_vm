#!/bin/bash
# РСЃРїРѕР»СЊР·РѕРІР°РЅРёРµ:
#   grant_access 'E:\path\to\folder'          в†’ /workspace/mnt/e/path/to/folder
#   grant_access 'E:\path\to\folder' alias    в†’ /workspace/mnt/alias

WINDOWS_PATH="$1"
ALIAS="$2"

if [ -z "$WINDOWS_PATH" ]; then
    echo "РСЃРїРѕР»СЊР·РѕРІР°РЅРёРµ: grant_access <windows_path> [alias]"
    exit 1
fi

DRIVE=$(echo "$WINDOWS_PATH" | head -c1 | tr 'A-Z' 'a-z')
REST=$(echo "$WINDOWS_PATH" | cut -c3- | sed 's/\\/\//g')
HOST_PATH="/host_mnt/${DRIVE}${REST}"

if [ ! -d "$HOST_PATH" ]; then
    echo "РћС€РёР±РєР°: $HOST_PATH РЅРµ СЃСѓС‰РµСЃС‚РІСѓРµС‚ (РёР· $WINDOWS_PATH)"
    echo "РџСЂРѕРІРµСЂСЊ, С‡С‚Рѕ РґРёСЃРє ${DRIVE^^}: РґРѕР±Р°РІР»РµРЅ РІ docker-compose.yml"
    exit 1
fi

if [ -n "$ALIAS" ]; then
    MOUNT_POINT="/workspace/mnt/$ALIAS"
else
    MOUNT_POINT="/workspace/mnt/${DRIVE}${REST}"
fi

if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
    echo "РЈР¶Рµ РїСЂРёРјРѕРЅС‚РёСЂРѕРІР°РЅРѕ: $MOUNT_POINT"
    # РЎРѕС…СЂР°РЅРёС‚СЊ РІ СЃРїРёСЃРѕРє (Р±РµР· РґСѓР±Р»РµР№)
    GRANT_LIST="/root/.grant_data/grant_list"
    if [ -f "$GRANT_LIST" ]; then
        grep -Fxq "$WINDOWS_PATH" "$GRANT_LIST" 2>/dev/null || echo "$WINDOWS_PATH" >> "$GRANT_LIST"
    else
        echo "$WINDOWS_PATH" > "$GRANT_LIST"
    fi
    exit 0
fi

mkdir -p "$MOUNT_POINT"
mount --bind "$HOST_PATH" "$MOUNT_POINT"

# РЎРѕС…СЂР°РЅРёС‚СЊ РІ СЃРїРёСЃРѕРє (Р±РµР· РґСѓР±Р»РµР№)
GRANT_LIST="/root/.grant_data/grant_list"
if [ -f "$GRANT_LIST" ]; then
    grep -Fxq "$WINDOWS_PATH" "$GRANT_LIST" 2>/dev/null || echo "$WINDOWS_PATH" >> "$GRANT_LIST"
else
    echo "$WINDOWS_PATH" > "$GRANT_LIST"
fi

echo "Р”РѕСЃС‚СѓРї РІС‹РґР°РЅ: $WINDOWS_PATH"
echo "  РљРѕРЅС‚РµР№РЅРµСЂ: $MOUNT_POINT"
