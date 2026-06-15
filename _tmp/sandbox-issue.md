# Проблема: Sandbox не инициализируется из-за монтирования Windows-диска

## Что произошло

При попытке выполнить `sbx apt update` скрипт сообщал:

```
Сэндбокс не инициализирован. Запусти один раз:
  fakeroot fakechroot debootstrap --variant=fakechroot bookworm ~/sandbox http://deb.debian.org/debian/
```

## Корневая причина

В AGENT.md написано, что для инициализации sandbox нужно выполнить:

```bash
fakeroot fakechroot debootstrap --variant=fakechroot bookworm ~/sandbox http://deb.debian.org/debian/
```

Проблема в том, что **`~/sandbox` — это не обычная директория, а смонтированный Windows-диск**.

Проверка показала:

```bash
$ mount | grep sandbox
O:\ on /home/aiuser/sandbox type 9p (rw,noatime,aname=drvfs;path=O:\;...)

$ ls -la ~/sandbox/
total 4
drwxrwxrwx 1 root root 4096 Jun 15 11:33 .
drwxr-xr-x aiuser aiuser 4096 Jun 15 11:29 ..
```

То есть:
- `~/sandbox` смонтирован на диск `O:` через протокол 9p (интеграция WSL с файловой системой Windows)
- Директория пуста и принадлежит root
- Debootstrap **не может** записать файлы в эту точку монтирования — он падает с ошибкой "file already exists" при попытке извлечения пакетов
- Удалить эту директорию тоже нельзя ("Device or resource busy", потому что это active mount point)

## Как решил

### Шаг 1: Обнаружил, что `~/sandbox` недоступен для записи

```bash
$ touch ~/sandbox/test
touch: cannot touch '/home/aiuser/sandbox/test': No resource or device available
```

### Шаг 2: Создал sandbox в альтернативном месте

```bash
$ mkdir -p ~/sbx_tmp
$ fakeroot fakechroot debootstrap --variant=fakechroot bookworm ~/sbx_tmp http://deb.debian.org/debian/
```

Debootstrap успешно установил базовую систему Debian Bookworm в `~/sbx_tmp` (~150-300 MB).

### Шаг 3: Проверил, что apt работает напрямую

```bash
$ fakeroot fakechroot chroot ~/sbx_tmp apt update
Get:2 http://deb.debian.org/debian bookworm/main Translation-en [6107 kB]
Reading package lists...
All packages are up to date.
```

Это работает, потому что `~/sbx_tmp` — обычная директория в ext4 (или tmpfs) домашней папки, без проблем с записью.

### Шаг 4: Обнаружил, что скрипт `sbx` зашит на `$HOME/sandbox`

Скрипт в `/usr/local/bin/sbx` жёстко указывает `SANDBOX="$HOME/sandbox"`, и попытка его изменить не удалась из-за прав:

```bash
$ cat $(which sbx)
SANDBOX="$HOME/sandbox"  # <-- захардкожено

$ ls -la /usr/local/bin/sbx
-rwxr-xr-x 1 root root ...  # owned by root, aiuser не может перезаписать
```

Попытка создать скрипт в `/workspace/` тоже не удалась — директория `/workspace` принадлежит root и доступна только для чтения.

### Шаг 5: Рабочее решение

Запускать команды напрямую без обёртки `sbx`:

```bash
fakeroot fakechroot chroot ~/sbx_tmp apt install -y <пакет>
```

## Что нужно сделать при сбросе окружения

Чтобы sandbox работал "из коробки", нужно одно из:

### Вариант A: Не монтировать O:\ на ~/sandbox

Если при настройке WSL есть возможность не делать `O:\` точкой монтирования в `~/sandbox`, sandbox будет работать как ожидается — debootstrap запишет файлы в обычную ext4-директорию.

### Вариант B: Изменить скрипт sbx (если есть root-доступ)

```bash
# Заменить строку SANDBOX="$HOME/sandbox" на:
SANDBOX="$HOME/sbx_tmp"
```

И выполнить debootstrap в `~/sbx_tmp`:

```bash
fakeroot fakechroot debootstrap --variant=fakechroot bookworm ~/sbx_tmp http://deb.debian.org/debian/
```

### Вариант C: Использовать переменную окружения

Добавить в `.bashrc`:

```bash
export SBX_ROOT="$HOME/sbx_tmp"
```

И изменить скрипт `sbx`:

```bash
SANDBOX="${SBX_ROOT:-$HOME/sandbox}"
```

## Итого

| Что | Статус |
|-----|--------|
| `~/sandbox` | Смонтирован на O:\, debootstrap не работает |
| `~/sbx_tmp` | Рабочий sandbox, apt install функционирует |
| Скрипт `sbx` | Указывает на `$HOME/sandbox`, не менять без root |
| Рабочий путь | `fakeroot fakechroot chroot ~/sbx_tmp apt ...` |
