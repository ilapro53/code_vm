FROM debian:bookworm-slim

ARG AGENT=mimo

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

RUN apt-get update && apt-get install -y \
    curl ca-certificates git bash gosu dos2unix \
    debootstrap fakeroot fakechroot \
    tree vim nano htop jq unzip zip rsync findutils procps net-tools iputils-ping dnsutils wget \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -u 1001 -s /bin/bash aiuser

# Установка AI-агента
COPY agents/${AGENT}/install.sh /tmp/install.sh
RUN chmod +x /tmp/install.sh && /tmp/install.sh

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
