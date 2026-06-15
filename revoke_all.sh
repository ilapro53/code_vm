#!/bin/bash
# Размонтировать всё внутри /workspace/mnt (корректно обрабатывает пробелы в путях)

awk '$5 ~ /^\/workspace\/mnt\// {print $5}' /proc/self/mountinfo | sort -r | while IFS= read -r mp; do
    real_mp=$(printf '%b' "$mp")
    umount "$real_mp" && echo "Закрыто: $real_mp"
done

find /workspace/mnt -mindepth 1 -type d -empty -delete 2>/dev/null

# Очистить список grant
rm -f /root/.grant_data/grant_list
