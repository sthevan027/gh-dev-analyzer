# GH Dev Analyzer - Script principal
# Analisa perfil do GitHub e gera relatório HTML

param(
    [string]$Username = "",
    [string]$OutputPath = ""
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $scriptDir
. "$rootDir\src\analyzer.ps1"

try {
    Invoke-Analyzer -Username $Username -OutputPath $OutputPath
} catch {
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
