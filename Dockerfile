ARG AGENT=mimo

FROM debian:bookworm-slim

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

RUN apt-get update && apt-get install -y curl ca-certificates git bash gosu \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -u 1001 -s /bin/bash aiuser

# Установка AI-агента
COPY agents/ /tmp/agents/
RUN if [ -f /tmp/agents/${AGENT}/install.sh ]; then \
      chmod +x /tmp/agents/${AGENT}/install.sh && \
      /tmp/agents/${AGENT}/install.sh; \
    fi

# Скрипты управления доступом
COPY entrypoint.sh /entrypoint.sh
COPY grant_access.sh /usr/local/bin/grant_access
COPY revoke_access.sh /usr/local/bin/revoke_access
COPY revoke_all.sh /usr/local/bin/revoke_all

# Исправить CRLF -> LF (на случай редактирования в Windows)
RUN sed -i 's/\r$//' /entrypoint.sh \
    /usr/local/bin/grant_access \
    /usr/local/bin/revoke_access \
    /usr/local/bin/revoke_all

RUN chmod +x /entrypoint.sh /usr/local/bin/grant_access /usr/local/bin/revoke_access /usr/local/bin/revoke_all

WORKDIR /workspace

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]
