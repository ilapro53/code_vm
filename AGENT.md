# AI Agent Context

## Доступные пути

- **Данные**: `/workspace/input/` — только для чтения
- **Рабочая область**: `/workspace/` — пиши сюда
- **Windows диски**:
  - `E:\` → `/host_mnt/e/`
  - `T:\` → `/host_mnt/t/`
  - `O:\` → `/host_mnt/o/`
- **Выданные папки**: `/workspace/mnt/` — смонтированы через `grant_access`

## Управление доступом

Эти команды может выполнять **только пользователь (root)**:

```bash
grant_access 'E:\path\to\folder'          # → /workspace/mnt/e/path/to/folder
grant_access 'E:\path\to\folder' alias    # → /workspace/mnt/alias
revoke_access alias                         # отозвать доступ
revoke_all                                  # отозвать всё
```

## Доступные команды

- `mimo` — AI-агент
- `grant_access`, `revoke_access`, `revoke_all` — только для root

## Важно

- `/host_mnt/` закрыт (chmod 700 root) — используй `grant_access`
- `/workspace/input/` — только для чтения
- `/workspace/` — твоя рабочая область
