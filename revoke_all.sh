#!/bin/bash
# Удалить все симлинки в /workspace/mnt

find /workspace/mnt -mindepth 1 -type l -delete 2>/dev/null
find /workspace/mnt -depth -type d -empty -delete 2>/dev/null

: > /workspace/.grant_data/grant_list
chmod 644 /workspace/.grant_data/grant_list 2>/dev/null

echo "Все симлинки удалены, список grant очищен"
