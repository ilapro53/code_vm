# code_vm

Docker-окружение для AI-агентов.

## Быстрый старт

```powershell
.\ai.ps1 up
.\ai.ps1 bash
.\ai.ps1 agent
```

## ai.ps1

| Действие | Команда | Описание |
|----------|---------|----------|
| Запуск | `.\ai.ps1 up` | Запустить контейнеры |
| Запуск (агент) | `.\ai.ps1 up -Agent mimo` | С агентов |
| Остановка | `.\ai.ps1 down` | Остановить контейнеры |
| Bash | `.\ai.ps1 bash` | Bash (aiuser) |
| Bash root | `.\ai.ps1 bash -Root` | Bash (root) |
| Агент | `.\ai.ps1 agent` | Запустить AI-агент |
| Сброс | `.\ai.ps1 reset` | Удалить контейнеры и тома |
| Пересоздание | `.\ai.ps1 recreate` | Сбросить контейнер и данные |
| Пересборка | `.\ai.ps1 rebuild` | Пересобрать образ (--no-cache) |
| Перезапуск | `.\ai.ps1 restart` | Перезапустить контейнер |
| Статус | `.\ai.ps1 status` | Показать статус контейнеров |
| Доступ | `.\ai.ps1 grant 'T:\path' [alias]` | Выдать доступ |
| Отзыв | `.\ai.ps1 revoke alias` | Отозвать доступ |
| Всё | `.\ai.ps1 revoke_all` | Размонтировать всё |

### Примеры

```powershell
.\ai.ps1 up
.\ai.ps1 up -Agent mimo
.\ai.ps1 reset
.\ai.ps1 recreate
.\ai.ps1 rebuild
.\ai.ps1 restart
.\ai.ps1 status
.\ai.ps1 agent
.\ai.ps1 grant 'T:\backups' backups
.\ai.ps1 revoke backups
.\ai.ps1 revoke 'T:\path'
.\ai.ps1 revoke_all
```

## Docker (без обёртки)

```powershell
docker compose up -d --build --build-arg AGENT=mimo
docker exec -u root -it code_vm-ai-tool-1 /bin/bash
docker exec -u root -it code_vm-ai-tool-1 /root/.mimocode/bin/mimo
```

## Структура

| Файл | Назначение |
|------|-----------|
| `Dockerfile` | Образ Debian + установка агента |
| `docker-compose.yml` | Конфиг с примонтированными дисками |
| `grant_access.sh` | Bind-mount папки Windows |
| `revoke_access.sh` | Отмонирование папки |
| `revoke_all.sh` | Размонтировать всё в /workspace/mnt |
| `entrypoint.sh` | Инициализация и запуск от aiuser |
| `agents/` | AI-агенты |

## AI-агенты

Добавьте новый агент в `agents/<name>/`:

```
agents/
  mimo/
    install.sh    # скрипт установки
    config.json   # {"name": "mimo", "binary": "/path/to/binary"}
```

`config.json` обязателен — содержит путь к бинарному файлу агента.

## Примонтированные диски

| Windows | В контейнере |
|---------|-------------|
| E:\ | /host_mnt/e |
| T:\ | /host_mnt/t |
| O:\ | /host_mnt/o |

Доступ к `/host_mnt/` закрыт. Используй `grant_access` для bind-mount.

## WSL

```powershell
wsl -e ln -sfn /mnt/t/ ./mnt/t_drive
```
