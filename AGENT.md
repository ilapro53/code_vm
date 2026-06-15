# AI Agent Context

## Доступные пути

- **Данные**: `/workspace/input/` — только для чтения
- **Рабочая область**: `/workspace/` — пиши сюда
- **Выданные папки и разрешенные диски**: `/workspace/mnt/` — смонтированы через `grant_access`

## Sandbox (apt без root)

```bash
sbx apt update
sbx apt install -y htop ffmpeg python3-dev
sbx /usr/bin/ffmpeg -version
sbx /bin/bash
```

Персистентный через `./sandbox` volume (~150-300MB, один раз).
Инициализация: `fakeroot fakechroot debootstrap --variant=fakechroot bookworm ~/sandbox http://deb.debian.org/debian/`

## Управление доступом

Эти команды может выполнять **только пользователь (root)**:

```bash
grant_access 'E:\path\to\folder'          # → /workspace/mnt/e/path/to/folder
grant_access 'E:\path\to\folder' alias    # → /workspace/mnt/alias
revoke_access alias                         # отозвать доступ
revoke_all                                  # отозвать всё
```

## Важно

- `/host_mnt/` закрыт (chmod 700 root)
- `/workspace/input/` — только для чтения
- `/workspace/` — твоя рабочая область, создавай папки для задач, чтобы держать ее в порядке
