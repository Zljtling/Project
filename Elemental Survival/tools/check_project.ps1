param(
    [string]$Godot = 'E:\Program Files\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe'
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
foreach ($name in @('prototype', 'growth', 'survival', 'exploration', 'content_sync', 'village', 'forge', 'setup', 'balance', 'region', 'house_entry', 'region_review', 'runtime_world', 'art_readability', 'revision', 'presentation_motion', 'environment_presentation', 'settlement_spawn', 'tower')) {
    $log = Join-Path $projectRoot "logs\$name-checks.log"
    # MultiMesh readback requires a real renderer; the dummy headless backend returns identity transforms.
    [string[]]$renderArgs = if ($name -eq 'environment_presentation') { @('--rendering-method', 'gl_compatibility') } else { @('--headless') }
    & $Godot @renderArgs --log-file (Join-Path $projectRoot 'logs\godot-runtime.log') --path $projectRoot --script "res://tests/${name}_checks.gd" *> $log
    $engineExit = $LASTEXITCODE
    $content = Get-Content -LiteralPath $log -Raw
    $summary = Select-String -LiteralPath $log -Pattern '^RESULT:'
    Write-Output $summary.Line
    if ($engineExit -ne 0 -or $content -match 'SCRIPT ERROR|ERROR:|FAIL  ' -or !$summary) {
        Write-Output "Check '$name' failed; engine exit code: $engineExit"
        Write-Output $content
        exit 1
    }
}
Write-Output 'All project checks passed.'
