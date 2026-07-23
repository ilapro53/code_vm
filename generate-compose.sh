#!/bin/bash
# Генерация docker-compose.yml для Linux
# Аналог generate-compose.ps1
# Использование: ./generate-compose.sh [--output docker-compose.yml]

set -e

OUTPUT="${1:-docker-compose.yml}"
COMPOSE_DIR="$(cd "$(dirname "$0")" && pwd)"

# Собираем точки монтирования — все папки рядом с compose-директорией
VOLUMES=()
VOLUMES+=("      - ./mnt:/workspace/mnt:rw")
VOLUMES+=("      - ./input:/workspace/input:ro")
VOLUMES+=("      - ./grant_data:/workspace/.grant_data:rw")

# Добавляем /mnt/* диски если существуют
for mount in /mnt/*; do
    [ -d "$mount" ] || continue
    name=$(basename "$mount")
    VOLUMES+=("      - ${mount}:/host_mnt/${name}:rw")
done

# Linux home
if [ -d "/home" ]; then
    VOLUMES+=("      - /home:/host_mnt/home:rw")
fi

VOLUMES_BLOCK=$(printf "%s\n" "${VOLUMES[@]}")

cat > "$OUTPUT" <<COMPOSEYML
services:
  ai-tool:
    build:
      context: .
      args:
        AGENT: mimo
    volumes:
${VOLUMES_BLOCK}
    cap_add:
      - SYS_ADMIN
    stdin_open: true
    tty: true
COMPOSEYML

echo "Сгенерирован $OUTPUT с ${#VOLUMES[@]} точками монтирования"
