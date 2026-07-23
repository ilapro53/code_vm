#!/bin/bash
# Установка AI-агента Mimo (Xiaomi)
set -e

if curl -fsSL --connect-timeout 5 --max-time 10 https://mimo.xiaomi.com/install -o /tmp/mimo_install 2>/dev/null; then
    chmod +x /tmp/mimo_install
    /tmp/mimo_install 2>/dev/null || true
    echo "✓ Mimo установлен"
else
    echo "⚠ Mimo: не удалось скачать (нет доступа к mimo.xiaomi.com)"
    echo "  Установи вручную после запуска контейнера."
fi
