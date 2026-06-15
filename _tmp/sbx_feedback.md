# Feedback: Multiple Sandboxes for `sbx`

## Что изменено

Скрипт `sbx` доработан для поддержки **нескольких sandbox'ов**. Каждый sandbox — отдельная изолированная Debian-система со своими пакетами.

## Установка

Скопировать обновлённый скрипт в `/usr/local/bin/sbx` (требуется root):

```bash
cp sbx /usr/local/bin/sbx
chmod +x /usr/local/bin/sbx
```

## Новые команды

| Команда | Описание |
|---------|----------|
| `sbx --init [<имя>]` | Создать sandbox. Имя по умолчанию — `sandbox` |
| `sbx --rm <имя>` | Удалить конкретный sandbox |
| `sbx --rm-all` | Удалить все sandbox'ы |
| `sbx --list` | Показать список всех sandbox'ов с размерами |
| `sbx --status [<имя>]` | Подробная информация о sandbox |
| `sbx -n <имя> <команда>` | Запустить команду в указанном sandbox |

## Примеры использования

```bash
# Создать два sandbox'а для разных задач
sbx --init web
sbx --init ml

# Установить nginx в sandbox "web"
sbx -n web apt update
sbx -n web apt install -y nginx

# Установить ML-пакеты в sandbox "ml"
sbx -n ml apt update
sbx -n ml apt install -y python3-pip numpy

# Посмотреть что установлено
sbx --list

# Запустить программу
sbx -n web /usr/sbin/nginx -v
sbx -n ml /usr/bin/python3 -c "import numpy; print(numpy.__version__)"

# Удалить sandbox когда не нужен
sbx --rm web
```

## Текст для добавления в AGENT.md

Добавить в секцию **Sandbox** после блока "Очистка кэша":

```markdown
## Несколько sandbox'ов

Sandbox поддерживает изолированные окружения для разных задач.

**Создание:**
```bash
sbx --init web        # sandbox для веб-разработки
sbx --init ml         # sandbox для ML/Python
```

**Использование конкретного sandbox:**
```bash
sbx -n web apt install -y nginx
sbx -n ml apt install -y python3-pip
sbx -n web /usr/sbin/nginx -v
```

**Управление:**
```bash
sbx --list             # все sandbox'ы с размерами
sbx --status web       # подробности о sandbox
sbx --rm web           # удалить sandbox
sbx --rm-all           # удалить все
```

**Совет:** Каждый sandbox хранится отдельно (`~/sandbox`, `~/web`, `~/ml`). Используйте разные sandbox'ы для изоляции окружений — это позволяет не засорять основной и экспериментировать без риска.
```

## Размеры

- Один пустой sandbox: ~150-300 MB
- С python3 + pip: ~400-500 MB
- С полным ML-стеком: ~1-2 GB

## Ограничения

- Все sandbox'и в `~/` ( Home directory ), при пересоздании контейнера удаляются
- fakeroot/fakechroot не работают с некоторыми бинарниками (Go, Rust — прямые syscalls)
- DNS-конфиг синхронизируется из хоста при каждом запуске
