#!/bin/bash
# Установка Pi Coding Agent (@earendil-works/pi-coding-agent)

set -e

# Установка Node.js если ещё нет
if ! command -v node &>/dev/null; then
    echo "Устанавливаю Node.js..."
    apt-get update -qq
    apt-get install -y -qq nodejs npm
fi

# Установка Pi глобально
npm install -g @earendil-works/pi-coding-agent@latest

echo "✓ Pi Coding Agent установлен: $(pi --version 2>/dev/null || pi -v 2>/dev/null || echo 'ok')"
