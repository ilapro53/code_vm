param(
    [Parameter(Mandatory=$false, Position=0)]
    [ValidateSet("up", "down", "grant", "revoke", "revoke_all", "bash", "mimo")]
    [string]$Action,

    [Parameter(Position=1, Mandatory=$false)]
    [string]$Param1,

    [Parameter(Position=2, Mandatory=$false)]
    [string]$Param2,

    [Parameter(Mandatory=$false)]
    [switch]$Root,

    [Parameter(Mandatory=$false)]
    [Alias("h")]
    [switch]$Help,

    [Parameter(Mandatory=$false, ValueFromRemainingArguments=$true)]
    [string[]]$RemainingArgs
)

# --- НАСТРОЙКИ ---
$ComposeDir = "O:\code_vm"
$ContainerName = "code_vm-ai-tool-1"
$DefaultUser = "aiuser"

# КАСТОМНЫЙ КОМПАКТНЫЙ HELP
if ($Help -or -not $Action) {
    Write-Host "`nAI Container Wrapper" -ForegroundColor Cyan
    Write-Host "Использование: " -NoNewline; Write-Host ".\ai.ps1 <Действие> [Параметры]" -ForegroundColor Yellow
    
    Write-Host "`nДоступные действия:" -ForegroundColor DarkCyan
    Write-Host "  up            " -NoNewline; Write-Host "Запустить контейнеры в фоне (docker compose up -d)" -ForegroundColor Gray
    Write-Host "  down          " -NoNewline; Write-Host "Остановить и удалить контейнеры (docker compose down)" -ForegroundColor Gray
    Write-Host "  grant         " -NoNewline; Write-Host "Выдать доступ к папке. Формат: grant <Путь_Win> [алиас]" -ForegroundColor Gray
    Write-Host "  revoke        " -NoNewline; Write-Host "Отозвать доступ у папки или алиаса" -ForegroundColor Gray
    Write-Host "  revoke_all    " -NoNewline; Write-Host "Сбросить права доступа для ВСЕХ смонтированных папок" -ForegroundColor Gray
    Write-Host "  bash          " -NoNewline; Write-Host "Запустить интерактивный Bash сеанс" -ForegroundColor Gray
    Write-Host "  mimo          " -NoNewline; Write-Host "Запустить mimo по полному пути от имени root" -ForegroundColor Gray
    
    Write-Host "`nМодификаторы:" -ForegroundColor DarkCyan
    Write-Host "  -Root         " -NoNewline; Write-Host "Выполнять команды bash от root (иначе от aiuser)" -ForegroundColor DarkYellow
    Write-Host "  -h, -Help     " -NoNewline; Write-Host "Показать эту компактную справку" -ForegroundColor DarkYellow
    
    Write-Host "`nПримеры использования:" -ForegroundColor Green
    Write-Host "  .\ai.ps1 up"
    Write-Host "  .\ai.ps1 mimo"
    Write-Host "  .\ai.ps1 mimo --help"
    Write-Host "  .\ai.ps1 bash -Root`n"
    return
}

# Функция для вызова docker compose с динамическим массивом аргументов
function Invoke-LocalCompose {
    Push-Location $ComposeDir
    try {
        docker compose $args
    } finally {
        Pop-Location
    }
}

switch ($Action) {
    "up" {
        Write-Host "Запуск окружения Docker Compose..." -ForegroundColor Green
        Invoke-LocalCompose up -d
    }
    
    "down" {
        Write-Host "Остановка окружения Docker Compose..." -ForegroundColor Yellow
        Invoke-LocalCompose down
    }

    "grant" {
        if (-not $Param1) {
            Write-Error "Не указан путь Windows. Пример: .\ai.ps1 grant 'T:\' t_drive"
            return
        }
        Write-Host "Выдача доступа к пути: $Param1" -ForegroundColor Green
        if ($Param2) {
            docker exec -u root -it $ContainerName grant_access $Param1 $Param2
        } else {
            docker exec -u root -it $ContainerName grant_access $Param1
        }
    }

    "revoke" {
        if (-not $Param1) {
            Write-Error "Не указан путь или алиас для отзыва доступа."
            return
        }
        Write-Host "Отзыв доступа для: $Param1" -ForegroundColor Yellow
        if ($Param2) {
            docker exec -u root -it $ContainerName revoke_access $Param1 $Param2
        } else {
            docker exec -u root -it $ContainerName revoke_access $Param1
        }
    }

    "revoke_all" {
        Write-Host "Сброс прав доступа для ВСЕХ папок внутри mnt/..." -ForegroundColor Red
        docker exec -u root -it $ContainerName revoke_all
    }

    "bash" {
        $User = if ($Root) { "root" } else { $DefaultUser }
        Write-Host "Вход в интерактивный Bash сеанс (Пользователь: $User)..." -ForegroundColor Cyan
        docker exec -u $User -it $ContainerName /bin/bash
    }

    "mimo" {
        $User = "aiuser"
        $MimoPath = "/root/.mimocode/bin/mimo"
        
        Write-Host "Запуск утилиты mimo внутри контейнера (Пользователь: $User)..." -ForegroundColor Magenta
        
        # Собираем аргументы, если они были переданы
        $MimoArgs = @()
        if ($Param1) { $MimoArgs += $Param1 }
        if ($Param2) { $MimoArgs += $Param2 }
        if ($RemainingArgs) { $MimoArgs += $RemainingArgs }

        if ($MimoArgs.Count -gt 0) {
            docker exec -u $User -it $ContainerName $MimoPath $MimoArgs
        } else {
            docker exec -u $User -it $ContainerName $MimoPath
        }
    }
}