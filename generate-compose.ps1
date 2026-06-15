param(
    [string]$OutputPath = "docker-compose.yml"
)

$ErrorActionPreference = "Stop"

# Get available Windows drives (skip system drives A, C, and network drives)
$drives = Get-PSDrive -PSProvider FileSystem | Where-Object {
    $_.Free -gt 0 -and
    $_.Root -notmatch '^\\' -and
    $_.Name -notin @('A', 'C', 'O')
} | Sort-Object Name

# Build volumes block
$volumes = @()
$volumes += "      - ./mnt:/workspace/mnt:rw"
$volumes += "      - ./input:/workspace/input:ro"
foreach ($drive in $drives) {
    $letter = $drive.Name.ToLower()
    $path = $drive.Root
        $volumes += "      - '${path}:/host_mnt/${letter}:rw'"
}

$volumesBlock = $volumes -join "`n"

$template = @"
services:
  ai-tool:
    build:
      context: .
      args:
        AGENT: mimo
    volumes:
${volumesBlock}
    cap_add:
      - SYS_ADMIN
    stdin_open: true
    tty: true
"@

[System.IO.File]::WriteAllText($OutputPath, $template, [System.Text.UTF8Encoding]::new($false))
Write-Host "Generated $OutputPath with $($drives.Count) drive(s): $($drives.Name -join ', ')"
