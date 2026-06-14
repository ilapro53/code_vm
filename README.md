# code_vm

Docker-окружение для работы с AI-инструментом MimoCode.

## Быстрый старт

```powershell
.\ai.ps1 up
.\ai.ps1 bash
.\ai.ps1 mimo
```

## ai.ps1 — основная обёртка

| Действие | Команда | Описание |
|----------|---------|----------|
| Запуск | `.\ai.ps1 up` | Запустить контейнеры |
| Остановка | `.\ai.ps1 down` | Остановить и удалить контейнеры |
| Bash | `.\ai.ps1 bash` | Интерактивный bash (aiuser) |
| Bash root | `.\ai.ps1 bash -Root` | Интерактивный bash (root) |
| Mimo | `.\ai.ps1 mimo` | Запустить mimo |
| Доступ | `.\ai.ps1 grant 'T:\path' [alias]` | Выдать доступ к папке |
| Отзыв | `.\ai.ps1 revoke alias` | Отозвать доступ |
| Всё | `.\ai.ps1 revoke_all` | Размонтировать всё в /workspace/mnt |

### Примеры

```powershell
.\ai.ps1 grant 'E:\data\project'
.\ai.ps1 grant 'T:\backups' backups
.\ai.ps1 revoke backups
.\ai.ps1 grant 'T:\path' path
.\ai.ps1 revoke 'T:\path'
.\ai.ps1 revoke_all
```

## Docker (без обёртки)

```powershell
docker compose up -d
docker exec -u root -it code_vm-ai-tool-1 /bin/bash
docker exec -u root -it code_vm-ai-tool-1 /root/.mimocode/bin/mimo
```

## Структура

| Файл | Назначение |
|------|-----------|
| `Dockerfile` | Образ Debian Bookworm + MimoCode |
| `docker-compose.yml` | Конфиг с примонтированными дисками |
| `grant_access.sh` | Bind-mount папки Windows в контейнер |
| `revoke_access.sh` | Отмонирование папки |
| `revoke_all.sh` | Размонтировать всё в /workspace/mnt |
| `entrypoint.sh` | Инициализация и запуск от aiuser |

## Примонтированные диски

| Windows | В контейнере |
|---------|-------------|
| E:\ | /workspace/host_mnt/e |
| T:\ | /workspace/host_mnt/t |
| O:\ | /workspace/host_mnt/o |

Доступ к `host_mnt` закрыт. Используйте `grant_access` для bind-mount.

## WSL

```powershell
wsl -e ln -sfn /mnt/t/ ./mnt/t_drive
```
