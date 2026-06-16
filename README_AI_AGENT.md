# AI Agent Context

## Доступные пути

- **Данные**: `/workspace/input/` — только для чтения
- **Рабочая область**: `/workspace/` — пиши сюда
- **Выданные папки и разрешенные диски**: `/workspace/mnt/` — symlink через `grant_access`
- **Список выданных доступов**: `/workspace/.grant_data/grant_list` — readable для агента, формат `WindowsPath|alias`

## Sandbox (установка пакетов без root)

Sandbox — изолированная Debian-система внутри контейнера. Позволяет ставить пакеты через apt без прав root.

**Инициализация (один раз, ~2-3 мин):**
```bash
fakeroot fakechroot debootstrap --variant=fakechroot bookworm ~/sandbox http://deb.debian.org/debian/
```

**Использование:**
```bash
# Обновить репозитории внутри sandbox
sbx apt update

# Установить пакеты (не требуют root)
sbx apt install -y htop ffmpeg python3-dev

# Запустить программу внутри sandbox
sbx /usr/bin/ffmpeg -version

# Интерактивная оболочка
sbx /bin/bash
# ... работа внутри sandbox ...
exit  # вернуться в основной контейнер
```

**Очистка кэша (по мере необходимости):**
```bash
sbx apt-get clean
sbx apt-get autoremove -y
```

**Важно:** sandbox хранится в `~/sandbox` (~150-300MB). Бинарники, делающие syscalls напрямую (некоторые Go/Rust), могут не работать через fakechroot.

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
