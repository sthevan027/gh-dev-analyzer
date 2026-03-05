# GH Dev Analyzer - Script principal
# Analisa perfil do GitHub e gera relatório

param(
    [string]$Username = "",
    [string]$OutputPath = ""
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootDir = Split-Path -Parent $scriptDir
. "$rootDir\src\analyzer.ps1"

if (-not $Username) {
    $Username = gh api user -q .login
    if (-not $Username) {
        Write-Error "Não foi possível obter o usuário. Passe -Username ou faça login com 'gh auth login'"
        exit 1
    }
}

Invoke-Analyzer -Username $Username -OutputPath $OutputPath
