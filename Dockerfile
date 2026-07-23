FROM debian:bookworm-slim

ARG AGENT=mimo

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# Установка системных пакетов — расширенный набор на основе реального использования
RUN apt-get update && apt-get install -y \
    # Базовые утилиты
    curl ca-certificates git bash gosu dos2unix \
    debootstrap fakeroot fakechroot \
    # Инструменты разработки/диагностики
    tree vim nano htop jq unzip zip rsync findutils procps net-tools iputils-ping dnsutils wget \
    btop tmux ripgrep bat fzf fd-find build-essential yq \
    netcat-openbsd gcc g++ make sqlite3 nmap strace sed ncdu gnupg gawk \
    imagemagick iproute2 pandoc ffmpeg redis-tools cmake screen \
    poppler-utils p7zip-full lsof gh shellcheck podman openssl \
    postgresql-client socat tesseract-ocr parallel tar ltrace \
    less coreutils zstd perl diffutils whois cron \
    plocate pigz entr clang libimage-exiftool-perl \
    rclone mtr aria2 ghostscript ninja-build \
    mosh moreutils patch stow \
    # Python (системный, для агентов)
    nodejs npm python3 python3-pip python3-venv \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -u 1001 -s /bin/bash aiuser

# Копирование и установка AI-агента
COPY agents/${AGENT}/install.sh /tmp/install.sh
RUN chmod +x /tmp/install.sh && /tmp/install.sh

# Если установлен opencode, записываем его бинарник в конфиг
RUN if [ -f "/tmp/opencode_binary_path" ]; then \
        BIN=$(cat /tmp/opencode_binary_path); \
        mkdir -p /agents/opencode; \
        echo "{\"name\": \"opencode\", \"binary\": \"$BIN\"}" > /agents/opencode/config.json; \
    fi

# Скрипты управления доступом
COPY entrypoint.sh /entrypoint.sh
COPY grant_access.sh /usr/local/bin/grant_access
COPY revoke_access.sh /usr/local/bin/revoke_access
COPY revoke_all.sh /usr/local/bin/revoke_all
COPY sbx.sh /usr/local/bin/sbx

# Контекст для AI-агента
COPY README_AI_AGENT.md /workspace/README_AI_AGENT.md
RUN chmod 444 /workspace/README_AI_AGENT.md

# Исправить CRLF -> LF (редактирование в Windows)
RUN dos2unix /entrypoint.sh \
    /usr/local/bin/grant_access \
    /usr/local/bin/revoke_access \
    /usr/local/bin/revoke_all \
    /usr/local/bin/sbx

RUN chmod +x /entrypoint.sh /usr/local/bin/grant_access /usr/local/bin/revoke_access /usr/local/bin/revoke_all /usr/local/bin/sbx

# Закрыть доступ к скриптам для aiuser (root может исполнять)
RUN chmod 700 /usr/local/bin/grant_access /usr/local/bin/revoke_access /usr/local/bin/revoke_all

WORKDIR /workspace

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]
