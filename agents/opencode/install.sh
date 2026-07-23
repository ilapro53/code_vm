#!/bin/bash
# Установка opencode AI agent (npm-пакет @opencode-ai/plugin)

set -e

export NVM_DIR="$HOME/.nvm"

# Установка Node.js если ещё нет
if ! command -v node &>/dev/null; then
    echo "Устанавливаю Node.js..."
    apt-get update -qq
    apt-get install -y -qq nodejs npm
fi

# Установка opencode глобально
npm install -g @opencode-ai/plugin@latest

# Определяем бинарник
if [ -f "/usr/lib/node_modules/@opencode-ai/plugin/bin/opencode" ]; then
    BINARY="/usr/lib/node_modules/@opencode-ai/plugin/bin/opencode"
elif [ -f "/usr/local/lib/node_modules/@opencode-ai/plugin/bin/opencode" ]; then
    BINARY="/usr/local/lib/node_modules/@opencode-ai/plugin/bin/opencode"
else
    BINARY="$(npm root -g)/@opencode-ai/plugin/bin/opencode"
fi

echo "✓ opencode установлен: $BINARY"
echo "$BINARY" > /tmp/opencode_binary_path
