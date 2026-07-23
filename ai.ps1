param(
    [Parameter(Mandatory=$false, Position=0)]
    [ValidateSet("up", "down", "reset", "recreate", "rebuild", "restart", "status", "grant", "revoke", "revoke_all", "grants", "bash", "agent")]
    [string]$Action,

    [Parameter(Position=1, Mandatory=$false)]
    [string]$Param1,

    [Parameter(Position=2, Mandatory=$false)]
    [string]$Param2,

    [Parameter(Mandatory=$false)]
    [ValidateSet("mimo")]
    [string]$Agent = "mimo",

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
$AgentsDir = Join-Path $ComposeDir "agents"

function Get-AgentBinary {
    param([string]$AgentName)
    $ConfigPath = Join-Path $AgentsDir "$AgentName/config.json"
    if (Test-Path $ConfigPath) {
        $config = Get-Content $ConfigPath | ConvertFrom-Json
        return $config.binary
    }
    return $null
}

function Get-AgentList {
    $dirs = Get-ChildItem $AgentsDir -Directory
    return ($dirs | ForEach-Object { $_.Name })
}

# КАСТОМНЫЙ КОМПАКТНЫЙ HELP
if ($Help -or -not $Action) {
    $AgentList = Get-AgentList
    Write-Host "`nAI Container Wrapper" -ForegroundColor Cyan
    Write-Host "Использование: " -NoNewline; Write-Host ".\ai.ps1 <Действие> [Параметры]" -ForegroundColor Yellow
    
    Write-Host "`nДоступные действия:" -ForegroundColor DarkCyan
    Write-Host "  up            " -NoNewline; Write-Host "Запустить контейнеры" -ForegroundColor Gray
    Write-Host "  down          " -NoNewline; Write-Host "Остановить и удалить контейнеры" -ForegroundColor Gray
    Write-Host "  grant         " -NoNewline; Write-Host "Выдать доступ к папке" -ForegroundColor Gray
    Write-Host "  revoke        " -NoNewline; Write-Host "Отозвать доступ" -ForegroundColor Gray
    Write-Host "  revoke_all    " -NoNewline; Write-Host "Размонтировать всё в /workspace/mnt" -ForegroundColor Gray
    Write-Host "  grants        " -NoNewline; Write-Host "Показать список выданных доступов" -ForegroundColor Gray
    Write-Host "  reset         " -NoNewline; Write-Host "Удалить контейнеры и тома (down -v)" -ForegroundColor Gray
    Write-Host "  recreate      " -NoNewline; Write-Host "Сбросить контейнер и данные (down -v + up)" -ForegroundColor Gray
    Write-Host "  rebuild       " -NoNewline; Write-Host "Пересобрать образ (build --no-cache)" -ForegroundColor Gray
    Write-Host "  restart       " -NoNewline; Write-Host "Перезапустить контейнер" -ForegroundColor Gray
    Write-Host "  status        " -NoNewline; Write-Host "Показать статус контейнеров" -ForegroundColor Gray
    Write-Host "  bash          " -NoNewline; Write-Host "Интерактивный Bash сеанс" -ForegroundColor Gray
    Write-Host "  agent         " -NoNewline; Write-Host "Запустить AI-агент" -ForegroundColor Gray
    
    Write-Host "`nМодификаторы:" -ForegroundColor DarkCyan
    Write-Host "  -Agent <name> " -NoNewline; Write-Host "AI-агент: $($AgentList -join ', ')" -ForegroundColor DarkYellow
    Write-Host "  -Root         " -NoNewline; Write-Host "Выполнять bash от root" -ForegroundColor DarkYellow
    Write-Host "  -h, -Help     " -NoNewline; Write-Host "Показать справку" -ForegroundColor DarkYellow
    
    Write-Host "`nПримеры:" -ForegroundColor Green
    Write-Host "  .\ai.ps1 up"
    Write-Host "  .\ai.ps1 up -Agent mimo"
    Write-Host "  .\ai.ps1 reset"
    Write-Host "  .\ai.ps1 recreate"
    Write-Host "  .\ai.ps1 rebuild"
    Write-Host "  .\ai.ps1 restart"
    Write-Host "  .\ai.ps1 status"
    Write-Host "  .\ai.ps1 agent"
    Write-Host "  .\ai.ps1 agent --help"
    Write-Host "  .\ai.ps1 bash -Root`n"
    return
}

# Генерация docker-compose.yml из шаблона
function Invoke-ComposeGenerate {
    $scriptPath = Join-Path $ComposeDir "generate-compose.ps1"
    if (Test-Path $scriptPath) {
        & $scriptPath -TemplatePath (Join-Path $ComposeDir "docker-compose.tpl.yml") -OutputPath (Join-Path $ComposeDir "docker-compose.yml")
    }
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
        Write-Host "Запуск контейнера (агент: $Agent)..." -ForegroundColor Green
        Invoke-ComposeGenerate
        Invoke-LocalCompose build
        Invoke-LocalCompose up -d
    }

    "status" {
        Write-Host "Статус контейнеров:" -ForegroundColor Cyan
        Invoke-LocalCompose ps
    }
    
    "down" {
        Write-Host "Остановка окружения..." -ForegroundColor Yellow
        Invoke-LocalCompose down
    }

    "reset" {
        Write-Host "Удаление контейнеров и томов..." -ForegroundColor Red
        Invoke-LocalCompose down -v
    }

    "recreate" {
        Write-Host "Сброс контейнера и данных..." -ForegroundColor Cyan
        Invoke-ComposeGenerate
        Invoke-LocalCompose down -v
        Invoke-LocalCompose up -d
    }

    "rebuild" {
        Write-Host "Пересборка образа (--no-cache)..." -ForegroundColor Cyan
        Invoke-ComposeGenerate
        Invoke-LocalCompose build --no-cache
    }

    "restart" {
        Write-Host "Перезапуск контейнера..." -ForegroundColor Cyan
        Invoke-LocalCompose restart
    }

    "grant" {
        if (-not $Param1) {
            Write-Error "Не указан путь Windows. Пример: .\ai.ps1 grant 'T:\' t_drive"
            return
        }
        Write-Host "Выдача доступа к пути: $Param1" -ForegroundColor Green
        docker exec -u root $ContainerName grant_access "$Param1" "$Param2"
    }

    "revoke" {
        if (-not $Param1) {
            Write-Error "Не указан путь или алиас для отзыва доступа."
            return
        }
        Write-Host "Отзыв доступа для: $Param1" -ForegroundColor Yellow
        docker exec -u root $ContainerName revoke_access "$Param1"
    }

    "revoke_all" {
        Write-Host "Сброс прав доступа для ВСЕХ папок внутри mnt/..." -ForegroundColor Red
        docker exec -u root $ContainerName revoke_all
    }

    "grants" {
        Write-Host "Список выданных доступов:" -ForegroundColor Cyan
        $lines = docker exec $ContainerName cat /workspace/grant_list 2>&1
        foreach ($line in $lines) {
            $parts = $line -split '\|', 2
            $winPath = $parts[0]
            if (-not $winPath) { continue }

            $drive = $winPath.Substring(0,1).ToLower()
            $rest = ($winPath.Substring(2) -replace '\\', '/').TrimEnd('/')
            Write-Host "  '$winPath' -> '/host_mnt/${drive}${rest}'"
        }
    }

    "bash" {
        $User = if ($Root) { "root" } else { $DefaultUser }
        Write-Host "Вход в Bash (Пользователь: $User)..." -ForegroundColor Cyan
        docker exec -u $User -it $ContainerName /bin/bash
    }

    "agent" {
        $binary = Get-AgentBinary $Agent
        if (-not $binary) {
            Write-Error "Агент '$Agent' не найден. Доступные: $(Get-AgentList -join ', ')"
            return
        }
        
        $User = "aiuser"
        Write-Host "Запуск агента '$Agent' ($binary)..." -ForegroundColor Magenta
        
        $AgentArgs = @()
        if ($Param1) { $AgentArgs += $Param1 }
        if ($Param2) { $AgentArgs += $Param2 }
        if ($RemainingArgs) { $AgentArgs += $RemainingArgs }

        $quotedArgs = $AgentArgs | ForEach-Object {
            if ($_ -match '\s') { "'$_'" } else { $_ }
        }
        $cmd = "docker exec -u $User -it $ContainerName $binary"
        if ($quotedArgs.Count -gt 0) {
            $cmd += " $($quotedArgs -join ' ')"
        }
        cmd.exe /c $cmd
    }
}
