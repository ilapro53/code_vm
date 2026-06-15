#!/bin/bash
# РСЃРїРѕР»СЊР·РѕРІР°РЅРёРµ:
#   revoke_access alias
#   revoke_access 'E:\path\to\folder'

ARG="$1"

if [ -z "$ARG" ]; then
    echo "РСЃРїРѕР»СЊР·РѕРІР°РЅРёРµ: revoke_access <alias РёР»Рё windows_path>"
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
    echo "РћС€РёР±РєР°: $MOUNT_POINT РЅРµ РїСЂРёРјРѕРЅС‚РёСЂРѕРІР°РЅ"
    exit 1
fi

umount "$MOUNT_POINT"
rmdir -p --ignore-fail-on-non-empty "$MOUNT_POINT" 2>/dev/null

# РЈРґР°Р»РёС‚СЊ РёР· СЃРїРёСЃРєР° grant
GRANT_LIST="/root/.grant_data/grant_list"
if [ -f "$GRANT_LIST" ]; then
    grep -Fxv "$ARG" "$GRANT_LIST" > "${GRANT_LIST}.tmp" 2>/dev/null || true
    mv "${GRANT_LIST}.tmp" "$GRANT_LIST"
fi

echo "Р”РѕСЃС‚СѓРї Р·Р°РєСЂС‹С‚: $ARG"
echo "  Р‘С‹Р»: $MOUNT_POINT"
