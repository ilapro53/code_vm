#!/bin/bash
# sbx — вход в fakeroot/fakechroot Debian-сэндбокс (apt без root)
# Использование: sbx <команда> [аргументы]
#   sbx apt update
#   sbx apt install -y htop ffmpeg
#   sbx /bin/bash

SANDBOX="$HOME/sandbox"

if [ ! -d "$SANDBOX/etc" ]; then
    echo "Сэндбокс не инициализирован. Запусти один раз:"
    echo "  fakeroot fakechroot debootstrap --variant=fakechroot bookworm $SANDBOX http://deb.debian.org/debian/"
    exit 1
fi

# Синхронизировать сеть — DNS может устареть при пересоздании контейнера
cat /etc/resolv.conf > "$SANDBOX/etc/resolv.conf" 2>/dev/null
cat /etc/hosts > "$SANDBOX/etc/hosts" 2>/dev/null

exec fakeroot fakechroot chroot "$SANDBOX" "$@"
