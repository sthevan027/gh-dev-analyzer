# ==========================================
# GitHub Analyzer CLI
# Autor: Sthevan Santos
# ==========================================

$ErrorActionPreference = "Stop"

# ---------- Verificar gh ----------
if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "Erro: GitHub CLI (gh) não instalado." -ForegroundColor Red
    exit 1
}

$auth = gh auth status 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Erro: Faça login primeiro com: gh auth login" -ForegroundColor Red
    exit 1
}

# ---------- Paths ----------
$OutDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$UserJson = Join-Path $OutDir "gh-user.json"
$ReposJson = Join-Path $OutDir "gh-repos.json"
$ReportPath = Join-Path $OutDir "analise-github-COMPLETA.md"

Write-Host "Coletando dados do GitHub..." -ForegroundColor Cyan

# ---------- Coleta ----------
gh api user | Set-Content $UserJson -Encoding UTF8
gh api "user/repos?per_page=100" --paginate | Set-Content $ReposJson -Encoding UTF8

$user = Get-Content $UserJson -Raw | ConvertFrom-Json
$repos = Get-Content $ReposJson -Raw | ConvertFrom-Json

if ($repos -isnot [array]) {
    $repos = @($repos)
}

# ---------- Métricas ----------
$totalRepos = $repos.Count
$totalStars = ($repos | Measure-Object stargazers_count -Sum).Sum
$totalForks = ($repos | Measure-Object forks_count -Sum).Sum
$totalIssues = ($repos | Measure-Object open_issues_count -Sum).Sum

$publicRepos = ($repos | Where-Object { -not $_.private }).Count
$privateRepos = ($repos | Where-Object { $_.private }).Count

$avgStars = if ($totalRepos -gt 0) {
    [math]::Round($totalStars / $totalRepos, 2)
}
else { 0 }

# ---------- Linguagens ----------
$langStats = $repos |
Where-Object { $_.language } |
Group-Object language |
Sort-Object Count -Descending

$totalLangRepos = ($repos | Where-Object language).Count

# ---------- Por Ano ----------
$byYear = $repos | ForEach-Object {
    $year = ([datetime]$_.created_at).Year
    [PSCustomObject]@{
        Year = $year
        Repo = $_.name
    }
} | Group-Object Year | Sort-Object Name

# ---------- Top Repos ----------
$topStars = $repos | Sort-Object stargazers_count -Descending | Select-Object -First 5
$topUpdated = $repos | Sort-Object updated_at -Descending | Select-Object -First 5
$topIssues = $repos | Sort-Object open_issues_count -Descending | Select-Object -First 5

# ---------- Relatório ----------
$md = @"
# Relatorio GitHub | @$($user.login)

Gerado em: $(Get-Date)

---

## Perfil

| Campo | Valor |
|------|------|
| Nome | $($user.name) |
| Bio | $($user.bio -replace "`n"," ") |
| Repos Publicos | $publicRepos |
| Repos Privados | $privateRepos |
| Seguidores | $($user.followers) |
| Seguindo | $($user.following) |
| Criado em | $($user.created_at) |

---

## Métricas Gerais

| Métrica | Valor |
|-------|------|
| Repositórios | $totalRepos |
| Estrelas | $totalStars |
| Forks | $totalForks |
| Issues abertas | $totalIssues |
| Média estrelas/repo | $avgStars |

---

## Linguagens

| Linguagem | Repos | % |
|-----------|------|----|
"@

foreach ($l in $langStats) {

    $pct = [math]::Round(($l.Count / $totalLangRepos) * 100, 1)

    $md += "`n| $($l.Name) | $($l.Count) | $pct% |"

}

$md += @"

---

## Repos por Ano

| Ano | Repos |
|----|------|
"@

foreach ($y in $byYear) {

    $md += "`n| $($y.Name) | $($y.Count) |"

}

$md += @"

---

## Top Repos (Stars)

| Repo | Stars |
|-----|------|
"@

foreach ($r in $topStars) {

    $md += "`n| $($r.name) | $($r.stargazers_count) |"

}

$md += @"

---

## Repos Mais Atualizados

| Repo | Atualizado |
|-----|------|
"@

foreach ($r in $topUpdated) {

    $md += "`n| $($r.name) | $($r.updated_at) |"

}

$md += @"

---

## Repos com Mais Issues

| Repo | Issues |
|-----|------|
"@

foreach ($r in $topIssues) {

    $md += "`n| $($r.name) | $($r.open_issues_count) |"

}

$md | Set-Content $ReportPath -Encoding UTF8

Write-Host "Relatorio gerado:" -ForegroundColor Green
Write-Host $ReportPath

Remove-Item $UserJson, $ReposJson -Force -ErrorAction SilentlyContinue