#!/bin/bash
# AI Container Wrapper — bash-эквивалент ai.ps1
# Использование: ./ai.sh <действие> [параметры]

set -e

COMPOSE_DIR="$(cd "$(dirname "$0")" && pwd)"
CONTAINER_NAME="code_vm-ai-tool-1"
DEFAULT_USER="aiuser"
AGENTS_DIR="$COMPOSE_DIR/agents"

usage() {
    echo ""
    echo "AI Container Wrapper"
    echo "Использование: $(basename "$0") <действие> [параметры]"
    echo ""
    echo "Действия:"
    echo "  up            Запустить контейнеры"
    echo "  down          Остановить и удалить контейнеры"
    echo "  grant         Выдать доступ к папке"
    echo "  revoke        Отозвать доступ"
    echo "  revoke_all    Размонтировать всё в /workspace/mnt"
    echo "  grants        Показать список выданных доступов"
    echo "  reset         Удалить контейнеры и тома (down -v)"
    echo "  recreate      Сбросить контейнер и данные (down -v + up)"
    echo "  rebuild       Пересобрать образ (build --no-cache)"
    echo "  restart       Перезапустить контейнер"
    echo "  status        Показать статус контейнеров"
    echo "  bash          Интерактивный Bash сеанс"
    echo "  agent         Запустить AI-агент"
    echo ""
    echo "Параметры:"
    echo "  -a, --agent <name>   AI-агент (по умолчанию: mimo)"
    echo "  -r, --root           Выполнять bash от root"
    echo "  -h, --help           Показать справку"
    echo ""
    echo "Примеры:"
    echo "  $(basename "$0") up"
    echo "  $(basename "$0") up -a opencode"
    echo "  $(basename "$0") reset"
    echo "  $(basename "$0") status"
    echo "  $(basename "$0") agent"
    echo "  $(basename "$0") bash -r"
    echo ""
}

get_agent_binary() {
    local agent_name="$1"
    local config_path="$AGENTS_DIR/$agent_name/config.json"
    if [ -f "$config_path" ]; then
        python3 -c "import json; print(json.load(open('$config_path'))['binary'])" 2>/dev/null
    fi
}

get_agent_list() {
    for d in "$AGENTS_DIR"/*/; do
        [ -d "$d" ] && basename "$d"
    done 2>/dev/null
}

# Разбор аргументов
ACTION=""
AGENT="mimo"
ROOT=false

while [ $# -gt 0 ]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        -a|--agent)
            AGENT="$2"
            shift 2
            ;;
        -r|--root)
            ROOT=true
            shift
            ;;
        -*)
            echo "Неизвестный параметр: $1"
            usage
            exit 1
            ;;
        *)
            if [ -z "$ACTION" ]; then
                ACTION="$1"
            fi
            shift
            ;;
    esac
done

if [ -z "$ACTION" ]; then
    usage
    exit 1
fi

cd "$COMPOSE_DIR"

case "$ACTION" in
    up)
        echo "Запуск контейнера (агент: $AGENT)..."
        docker compose build --build-arg "AGENT=$AGENT"
        docker compose up -d
        ;;

    status)
        echo "Статус контейнеров:"
        docker compose ps
        ;;

    down)
        echo "Остановка окружения..."
        docker compose down
        ;;

    reset)
        echo "Удаление контейнеров и томов..."
        docker compose down -v
        ;;

    recreate)
        echo "Сброс контейнера и данных..."
        docker compose down -v
        docker compose build --build-arg "AGENT=$AGENT"
        docker compose up -d
        ;;

    rebuild)
        echo "Пересборка образа (--no-cache)..."
        docker compose build --no-cache --build-arg "AGENT=$AGENT"
        ;;

    restart)
        echo "Перезапуск контейнера..."
        docker compose restart
        ;;

    grant)
        if [ -z "$2" ] && [ $# -lt 2 ]; then
            echo "Ошибка: не указан путь."
            echo "Пример: $(basename "$0") grant /path/to/folder alias"
            exit 1
        fi
        echo "Выдача доступа к пути: $2"
        docker exec -u root "$CONTAINER_NAME" grant_access "$2" "$3"
        ;;

    revoke)
        if [ -z "$2" ]; then
            echo "Ошибка: не указан путь или алиас для отзыва доступа."
            echo "Пример: $(basename "$0") revoke alias"
            exit 1
        fi
        echo "Отзыв доступа для: $2"
        docker exec -u root "$CONTAINER_NAME" revoke_access "$2"
        ;;

    revoke_all)
        echo "Сброс прав доступа для ВСЕХ папок..."
        docker exec -u root "$CONTAINER_NAME" revoke_all
        ;;

    grants)
        echo "Список выданных доступов:"
        docker exec "$CONTAINER_NAME" cat /workspace/grant_list 2>/dev/null || echo "(нет выданных доступов)"
        ;;

    bash)
        if [ "$ROOT" = true ]; then
            echo "Вход в Bash (Пользователь: root)..."
            docker exec -u root -it "$CONTAINER_NAME" /bin/bash
        else
            echo "Вход в Bash (Пользователь: $DEFAULT_USER)..."
            docker exec -u "$DEFAULT_USER" -it "$CONTAINER_NAME" /bin/bash
        fi
        ;;

    agent)
        binary=$(get_agent_binary "$AGENT")
        if [ -z "$binary" ]; then
            echo "Ошибка: агент '$AGENT' не найден."
            echo "Доступные: $(get_agent_list | tr '\n' ' ')"
            exit 1
        fi
        echo "Запуск агента '$AGENT' ($binary)..."
        shift 2 2>/dev/null || true
        docker exec -u "$DEFAULT_USER" -it "$CONTAINER_NAME" "$binary" "$@"
        ;;

    *)
        echo "Неизвестное действие: $ACTION"
        usage
        exit 1
        ;;
esac
