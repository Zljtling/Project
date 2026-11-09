param(
    [string]$Godot = 'E:\Program Files\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
& $Godot --path $projectRoot --log-file (Join-Path $projectRoot 'logs\village-runtime.log') 'res://scenes/regions/taishi/taishi_village.tscn'
