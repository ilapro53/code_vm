#!/bin/bash
set -e

# install_packages.sh — установка окружения AI-агента на Debian/Ubuntu
# Версия: 2.0 (доработана на основе реального опыта эксплуатации)
#
# Запускать от обычного юзера (с правом sudo), НЕ из-под root.
# Иначе uv/python/rust уедут в /root, а usermod добавит в docker рута.
if [ "$(id -u)" -eq 0 ]; then
  echo "Не запускай этот скрипт от root (sudo ./install_packages.sh)." >&2
  echo "Запусти от обычного юзера — sudo он вызовет сам, где нужно:" >&2
  echo "    ./install_packages.sh" >&2
  exit 1
fi

# Проверка, что sudo доступен
if ! command -v sudo >/dev/null 2>&1; then
  echo "Нужен sudo, но он не найден. Установи sudo и добавь юзера в sudoers." >&2
  exit 1
fi

echo "=== Установка окружения AI-агента ==="
echo "Основано на опросе 16 нейросетей + реальный опыт на Debian 13"
echo ""

# Обновление репозиториев
echo "[1/7] Обновление репозиториев..."
sudo apt-get update -qq

# Основные пакеты (расширенный набор)
echo "[2/7] Установка основных пакетов..."
sudo apt-get install -y \
 btop tmux git curl wget ripgrep jq bat fzf fd-find \
 build-essential yq bind9-dnsutils netcat-openbsd openssh-client \
 gcc g++ make sqlite3 zip unzip nmap vim strace \
 rsync sed ncdu gnupg gawk tree imagemagick \
 iproute2 pandoc ffmpeg redis-tools cmake screen \
 poppler-utils p7zip-full lsof gh shellcheck \
 podman nano openssl postgresql-client socat \
 tesseract-ocr parallel tar ltrace \
 less coreutils zstd perl diffutils whois cron \
 default-mysql-client plocate pigz procps \
 entr clang libimage-exiftool-perl \
 rclone mtr findutils aria2 \
 nvtop ghostscript ninja-build mosh moreutils \
 patch stow

# Docker (в Debian 13 docker-compose — это уже v2, дает 'docker compose')
echo "[3/7] Установка Docker..."
if ! command -v docker &>/dev/null; then
  sudo apt-get install -y docker.io docker-compose
  sudo usermod -aG docker "$USER" 2>/dev/null || true
  echo "  Docker установлен. Перелогинься, чтобы группа docker применилась."
else
  echo "  Docker уже установлен."
fi

# Python + ключевые библиотеки
echo "[4/7] Установка Python и библиотек..."
sudo apt-get install -y python3 python3-pip python3-venv

# Глобальные pip-пакеты (реально используемые)
sudo pip3 install --break-system-packages -q \
  pandas numpy httpie csvkit rich black ruff mypy pytest \
  requests beautifulsoup4 lxml playwright PyYAML \
  telethon openpyxl xlsxwriter cryptography \
  matplotlib trash-cli yamllint 2>/dev/null || \
pip3 install --user -q \
  pandas numpy httpie csvkit rich black ruff mypy pytest \
  requests beautifulsoup4 lxml playwright PyYAML \
  telethon openpyxl xlsxwriter cryptography \
  matplotlib trash-cli yamllint

# Playwright браузеры
if command -v playwright &>/dev/null; then
  echo "  Устанавливаю Playwright браузеры..."
  python3 -m playwright install chromium 2>/dev/null || true
fi

# uv — менеджер проектов Python
echo "[5/7] Установка uv..."
curl -LsSf https://astral.sh/uv/install.sh | sh || echo "  uv не установился (сеть?)"

# Языки: Node.js, Go, Rust
echo "[6/7] Установка Node.js, Go, Rust..."
sudo apt-get install -y nodejs npm 2>/dev/null || {
  curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
  sudo apt-get install -y nodejs
}
sudo apt-get install -y golang

if ! command -v rustup &>/dev/null; then
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y || \
    echo "  Rust не установился (сеть?)"
fi

# Глобальные npm-пакеты (AI-агенты)
echo "[7/7] Установка глобальных npm-пакетов..."
sudo npm install -g pnpm openclaw @opencode-ai/plugin tg-mtproto-cli 2>/dev/null || \
  echo "  Некоторые npm-пакеты не установились (возможно, нужна сеть)"

# Добавление npm-global в PATH
PROFILE="/etc/profile.d/npm-global.sh"
if [ ! -f "$PROFILE" ]; then
  echo 'export PATH="$PATH:/usr/local/lib/node_modules/.bin"' | sudo tee "$PROFILE" >/dev/null
fi

echo ""
echo "=== Установка завершена ==="
echo "Python: $(python3 --version 2>/dev/null || echo 'N/A')"
echo "pip:    $(pip3 --version 2>/dev/null || echo 'N/A')"
echo "Node:   $(node --version 2>/dev/null || echo 'N/A')"
echo "npm:    $(npm --version 2>/dev/null || echo 'N/A')"
echo "Go:     $(go version 2>/dev/null || echo 'N/A')"
echo "Rust:   $(rustc --version 2>/dev/null || echo 'N/A')"
echo "uv:     $(uv --version 2>/dev/null || echo 'N/A')"
echo "Docker: $(docker --version 2>/dev/null || echo 'N/A')"
echo ""
echo "Дополнительно:"
echo "  Playwright: $(python3 -m playwright --version 2>/dev/null || echo 'N/A')"
echo "  opencode:   $(opencode --version 2>/dev/null || echo 'N/A')"
echo "  openclaw:   $(openclaw --version 2>/dev/null || echo 'N/A')"
echo "  pnpm:       $(pnpm --version 2>/dev/null || echo 'N/A')"
