#!/bin/bash
# Р Р°Р·РјРѕРЅС‚РёСЂРѕРІР°С‚СЊ РІСЃС‘ РІРЅСѓС‚СЂРё /workspace/mnt (РєРѕСЂСЂРµРєС‚РЅРѕ РѕР±СЂР°Р±Р°С‚С‹РІР°РµС‚ РїСЂРѕР±РµР»С‹ РІ РїСѓС‚СЏС…)

awk '$5 ~ /^\/workspace\/mnt\// {print $5}' /proc/self/mountinfo | sort -r | while IFS= read -r mp; do
    real_mp=$(printf '%b' "$mp")
    umount "$real_mp" && echo "Р—Р°РєСЂС‹С‚Рѕ: $real_mp"
done

find /workspace/mnt -mindepth 1 -type d -empty -delete 2>/dev/null

# РћС‡РёСЃС‚РёС‚СЊ СЃРїРёСЃРѕРє grant
rm -rf /root/.grant_data
