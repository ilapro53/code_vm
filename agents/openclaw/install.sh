#!/bin/bash
# Установка OpenClaw AI Agent
set -e

# Установка Node.js если ещё нет
if ! command -v node &>/dev/null; then
    echo "Устанавливаю Node.js..."
    apt-get update -qq
    apt-get install -y -qq nodejs npm
fi

# Установка OpenClaw глобально
npm install -g openclaw@latest

echo "✓ OpenClaw установлен: $(openclaw --version 2>/dev/null || echo 'ok')"
