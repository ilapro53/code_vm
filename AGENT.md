# AI Agent Context

## Доступные пути

- **Данные**: `/workspace/input/` — только для чтения
- **Рабочая область**: `/workspace/` — пиши сюда
- **Выданные папки и разрешенные диски**: `/workspace/mnt/` — смонтированы через `grant_access`

## Инициализация sandbox (одноразовая, от aiuser)

```bash
init-sandbox    # fakeroot fakechroot debootstrap bookworm ~/sandbox
```

Занимает несколько минут. После — `~/sandbox` готов к использованию.

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
