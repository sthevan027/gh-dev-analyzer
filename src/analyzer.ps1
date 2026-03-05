# ==========================================
# GH Dev Analyzer - Módulo de análise GitHub
# Autor: Sthevan Santos
# Princípios: SOLID
# ==========================================

$ErrorActionPreference = "Stop"

#region Interface Pública

function Invoke-Analyzer {
    <#
    .SYNOPSIS
        Analisa um perfil GitHub e gera relatório HTML.
    .PARAMETER Username
        Login do usuário GitHub. Se vazio, usa o usuário autenticado.
    .PARAMETER OutputPath
        Caminho do arquivo de saída. Se vazio, gera {username}-{data}.html no diretório de reports.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Username = "",
        [Parameter(Mandatory = $false)]
        [string]$OutputPath = ""
    )

    Assert-GitHubCliAvailable
    $Username = Resolve-Username -Username $Username

    $tempDir = Get-TemporaryDataPath
    $userData = Get-GitHubUserData -Username $Username -TempDir $tempDir
    $reposData = Get-GitHubReposData -Username $Username -TempDir $tempDir
    Remove-TemporaryFiles -TempDir $tempDir

    $metrics = Get-AggregatedMetrics -User $userData -Repos $reposData
    $reportPath = Resolve-ReportPath -Username $Username -OutputPath $OutputPath
    $html = New-HtmlReport -User $userData -Repos $reposData -Metrics $metrics -Username $Username

    Save-Report -Content $html -Path $reportPath
    Write-Host "Relatório gerado:" -ForegroundColor Green
    Write-Host $reportPath

    return $reportPath
}

#endregion

#region Single Responsibility - Validação (S)

function Assert-GitHubCliAvailable {
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        throw "GitHub CLI (gh) não instalado. Instale em: https://cli.github.com/"
    }
    $null = gh auth status 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Faça login primeiro: gh auth login"
    }
}

#endregion

#region Single Responsibility - Resolução de parâmetros (S)

function Resolve-Username {
    param([string]$Username)
    if ([string]::IsNullOrWhiteSpace($Username)) {
        $Username = gh api user -q .login 2>$null
        if (-not $Username) { throw "Não foi possível obter o usuário. Passe -Username ou faça: gh auth login" }
    }
    return $Username.Trim()
}

function Resolve-ReportPath {
    param([string]$Username, [string]$OutputPath)
    $dateStr = Get-Date -Format "yyyy-MM-dd"
    $fileName = "${Username}-${dateStr}.html"
    if (-not [string]::IsNullOrWhiteSpace($OutputPath)) {
        return $OutputPath
    }
    $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $PSCommandPath }
    $rootDir = Split-Path -Parent $scriptDir
    $reportsDir = Join-Path $rootDir "reports"
    if (-not (Test-Path $reportsDir)) {
        New-Item -ItemType Directory -Path $reportsDir -Force | Out-Null
    }
    return Join-Path $reportsDir $fileName
}

#endregion

#region Single Responsibility - Coleta de dados (S)

function Get-TemporaryDataPath {
    $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $PSCommandPath }
    $rootDir = Split-Path -Parent $scriptDir
    $tempDir = Join-Path $rootDir ".gh-analyzer-temp"
    if (-not (Test-Path $tempDir)) {
        New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    }
    return $tempDir
}

function Get-GitHubUserData {
    param([string]$Username, [string]$TempDir)
    $endpoint = if ($Username) { "users/$Username" } else { "user" }
    $path = Join-Path $TempDir "gh-user.json"
    Write-Host "Coletando dados do usuário..." -ForegroundColor Cyan
    gh api $endpoint | Set-Content $path -Encoding UTF8
    $raw = Get-Content $path -Raw
    if (-not $raw) { throw "Falha ao obter dados do usuário." }
    return $raw | ConvertFrom-Json
}

function Get-GitHubReposData {
    param([string]$Username, [string]$TempDir)
    $endpoint = if ($Username) { "users/$Username/repos?per_page=100" } else { "user/repos?per_page=100" }
    $path = Join-Path $TempDir "gh-repos.json"
    Write-Host "Coletando repositórios..." -ForegroundColor Cyan
    gh api $endpoint --paginate | Set-Content $path -Encoding UTF8
    $raw = Get-Content $path -Raw
    if (-not $raw) { throw "Falha ao obter repositórios." }
    $repos = $raw | ConvertFrom-Json
    if ($repos -isnot [array]) { $repos = @($repos) }
    return $repos
}

function Remove-TemporaryFiles {
    param([string]$TempDir)
    Remove-Item (Join-Path $TempDir "*.json") -Force -ErrorAction SilentlyContinue
}

#endregion

#region Single Responsibility - Métricas (S)

function Get-AggregatedMetrics {
    param($User, $Repos)

    $totalRepos = $Repos.Count
    $totalStars = ($Repos | Measure-Object -Property stargazers_count -Sum).Sum
    $totalForks = ($Repos | Measure-Object -Property forks_count -Sum).Sum
    $totalIssues = ($Repos | Measure-Object -Property open_issues_count -Sum).Sum
    $publicRepos = ($Repos | Where-Object { -not $_.private }).Count
    $privateRepos = ($Repos | Where-Object { $_.private }).Count
    $archivedRepos = ($Repos | Where-Object { $_.archived }).Count
    $forkRepos = ($Repos | Where-Object { $_.fork }).Count
    $avgStars = if ($totalRepos -gt 0) { [math]::Round($totalStars / $totalRepos, 2) } else { 0 }

    $langStats = $Repos | Where-Object { $_.language } | Group-Object -Property language | Sort-Object Count -Descending
    $totalLangRepos = ($Repos | Where-Object { $_.language }).Count

    $byYear = $Repos | ForEach-Object {
        $year = ([datetime]$_.created_at).Year
        [PSCustomObject]@{ Year = $year; Repo = $_.name }
    } | Group-Object Year | Sort-Object Name

    $allTopics = @{}
    $Repos | Where-Object { $_.topics } | ForEach-Object {
        $_.topics | ForEach-Object { $allTopics[$_] = ($allTopics[$_] + 1) }
    }
    $topTopics = $allTopics.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First 15

    return [PSCustomObject]@{
        TotalRepos      = $totalRepos
        TotalStars      = $totalStars
        TotalForks      = $totalForks
        TotalIssues     = $totalIssues
        PublicRepos     = $publicRepos
        PrivateRepos    = $privateRepos
        ArchivedRepos   = $archivedRepos
        ForkRepos       = $forkRepos
        AvgStars        = $avgStars
        LangStats       = $langStats
        TotalLangRepos  = $totalLangRepos
        ByYear          = $byYear
        TopTopics       = $topTopics
        TopStars        = $Repos | Sort-Object stargazers_count -Descending | Select-Object -First 5
        TopUpdated      = $Repos | Sort-Object updated_at -Descending | Select-Object -First 5
        TopIssues       = $Repos | Where-Object { $_.open_issues_count -gt 0 } | Sort-Object open_issues_count -Descending | Select-Object -First 5
        AllReposSorted  = $Repos | Sort-Object stargazers_count -Descending
    }
}

#endregion

#region Single Responsibility - Geração de relatório HTML (S)

function New-HtmlReport {
    param($User, $Repos, $Metrics, [string]$Username)

    $dateStr = Get-Date -Format "dd/MM/yyyy HH:mm"
    $pageTitle = "GitHub - $Username - $(Get-Date -Format 'yyyy-MM-dd')"

    $profileTable = Get-ProfileTableHtml -User $User -Metrics $Metrics
    $generalTable = Get-GeneralMetricsTableHtml -Metrics $Metrics
    $reposTable = Get-AllReposTableHtml -Repos $Metrics.AllReposSorted
    $langTable = Get-LanguageTableHtml -Metrics $Metrics
    $yearTable = Get-YearTableHtml -Metrics $Metrics
    $topicsTable = Get-TopicsTableHtml -Metrics $Metrics
    $topStarsTable = Get-TopStarsTableHtml -Metrics $Metrics
    $topUpdatedTable = Get-TopUpdatedTableHtml -Metrics $Metrics
    $topIssuesTable = Get-TopIssuesTableHtml -Metrics $Metrics

    $privateCount = if ($User.PSObject.Properties['total_private_repos']) { $User.total_private_repos } else { "-" }
    $bio = if ($User.bio) { [System.Web.HttpUtility]::HtmlEncode($User.bio -replace "`n", " / ") } else { "-" }
    $userName = if ($User.name) { [System.Web.HttpUtility]::HtmlEncode($User.name) } else { "-" }

    $html = @"
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$pageTitle</title>
    <style>
        :root { --bg: #0d1117; --surface: #161b22; --border: #30363d; --text: #c9d1d9; --muted: #8b949e; --accent: #58a6ff; --green: #3fb950; }
        * { box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Noto Sans, sans-serif; background: var(--bg); color: var(--text); margin: 0; padding: 2rem; line-height: 1.6; }
        .container { max-width: 960px; margin: 0 auto; }
        h1 { font-size: 1.75rem; margin-bottom: 0.25rem; }
        .subtitle { color: var(--muted); font-size: 0.9rem; margin-bottom: 2rem; }
        h2 { font-size: 1.25rem; margin: 2rem 0 1rem; padding-bottom: 0.5rem; border-bottom: 1px solid var(--border); }
        table { width: 100%; border-collapse: collapse; margin-bottom: 1rem; font-size: 0.9rem; }
        th, td { padding: 0.5rem 0.75rem; text-align: left; border: 1px solid var(--border); }
        th { background: var(--surface); color: var(--muted); font-weight: 600; }
        tr:nth-child(even) { background: rgba(22,27,34,0.5); }
        a { color: var(--accent); text-decoration: none; }
        a:hover { text-decoration: underline; }
        .badge { display: inline-block; padding: 0.2rem 0.5rem; border-radius: 4px; font-size: 0.8rem; }
        .badge-public { background: rgba(63,185,80,0.2); color: var(--green); }
        .badge-private { background: rgba(139,148,158,0.2); color: var(--muted); }
        .footer { margin-top: 3rem; color: var(--muted); font-size: 0.85rem; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Relatório GitHub — @$Username</h1>
        <p class="subtitle">Gerado em $dateStr | GH Dev Analyzer</p>

        <h2>1. Perfil</h2>
        $profileTable

        <h2>2. Métricas gerais</h2>
        $generalTable

        <h2>3. Todos os repositórios ($($Metrics.TotalRepos))</h2>
        $reposTable

        <h2>4. Por linguagem</h2>
        $langTable

        <h2>5. Por ano de criação</h2>
        $yearTable

        <h2>6. Topics (Top 15)</h2>
        $topicsTable

        <h2>7. Top repositórios (estrelas)</h2>
        $topStarsTable

        <h2>8. Repositórios mais atualizados</h2>
        $topUpdatedTable

        <h2>9. Repositórios com mais issues</h2>
        $topIssuesTable

        <p class="footer">Relatório gerado pelo GH Dev Analyzer</p>
    </div>
</body>
</html>
"@

    # Substituir placeholders dos dados dinâmicos (tabelas já montadas)
    return $html
}

function Get-ProfileTableHtml {
    param($User, $Metrics)
    $privateCount = if ($User.PSObject.Properties['total_private_repos']) { $User.total_private_repos } else { "-" }
    $bioRaw = if ($User.bio) { $User.bio -replace "`n", " / " } else { "-" }
    $bio = [System.Net.WebUtility]::HtmlEncode($bioRaw)
    $nameRaw = if ($User.name) { $User.name } else { "-" }
    $userName = [System.Net.WebUtility]::HtmlEncode($nameRaw)
    $rows = @(
        "| Nome | $userName |",
        "| Login | $($User.login) |",
        "| Bio | $bio |",
        "| Repos públicos | $($Metrics.PublicRepos) |",
        "| Repos privados | $privateCount |",
        "| Seguidores | $($User.followers) |",
        "| Seguindo | $($User.following) |",
        "| Gists | $($User.public_gists) |",
        "| Criado em | $($User.created_at) |"
    )
    return Get-TableFromRows -Headers @("Campo", "Valor") -Rows $rows
}

function Get-GeneralMetricsTableHtml {
    param($Metrics)
    $rows = @(
        "| Repositórios | $($Metrics.TotalRepos) |",
        "| Estrelas | $($Metrics.TotalStars) |",
        "| Forks | $($Metrics.TotalForks) |",
        "| Issues abertas | $($Metrics.TotalIssues) |",
        "| Média estrelas/repo | $($Metrics.AvgStars) |",
        "| Repos arquivados | $($Metrics.ArchivedRepos) |",
        "| Repos fork | $($Metrics.ForkRepos) |"
    )
    return Get-TableFromRows -Headers @("Métrica", "Valor") -Rows $rows
}

function Get-TableFromRows {
    param([string[]]$Headers, [string[]]$Rows)
    $thead = "<thead><tr>" + (($Headers | ForEach-Object { "<th>$_</th>" }) -join "") + "</tr></thead>"
    $tbody = "<tbody>"
    foreach ($row in $Rows) {
        $cells = ($row -replace '^\|\s*' -replace '\s*\|$').Trim() -split '\s*\|\s*'
        if ($cells.Count -ge 2) {
            $tbody += "<tr><td>$($cells[0].Trim())</td><td>$($cells[1].Trim())</td></tr>"
        }
    }
    $tbody += "</tbody>"
    return "<table>$thead$tbody</table>"
}

function Get-AllReposTableHtml {
    param($Repos)
    $thead = "<thead><tr><th>#</th><th>Repositório</th><th>Visibilidade</th><th>⭐</th><th>Forks</th><th>Lang</th><th>Issues</th><th>Branch</th></tr></thead><tbody>"
    $i = 1
    foreach ($r in $Repos) {
        $vis = if ($r.private) { '<span class="badge badge-private">privado</span>' } else { '<span class="badge badge-public">público</span>' }
        $lang = if ($r.language) { $r.language } else { "-" }
        $url = "https://github.com/$($r.full_name)"
        $thead += "<tr><td>$i</td><td><a href='$url' target='_blank' rel='noopener noreferrer'>$($r.name)</a></td><td>$vis</td><td>$($r.stargazers_count)</td><td>$($r.forks_count)</td><td>$lang</td><td>$($r.open_issues_count)</td><td>$($r.default_branch)</td></tr>"
        $i++
    }
    return "<table>$thead</tbody></table>"
}

function Get-LanguageTableHtml {
    param($Metrics)
    if (-not $Metrics.LangStats -or $Metrics.TotalLangRepos -eq 0) {
        return "<p>Nenhuma linguagem detectada.</p>"
    }
    $thead = "<thead><tr><th>Linguagem</th><th>Repos</th><th>%</th></tr></thead><tbody>"
    foreach ($l in $Metrics.LangStats) {
        $pct = [math]::Round(($l.Count / $Metrics.TotalLangRepos) * 100, 1)
        $thead += "<tr><td>$($l.Name)</td><td>$($l.Count)</td><td>${pct}%</td></tr>"
    }
    return "<table>$thead</tbody></table>"
}

function Get-YearTableHtml {
    param($Metrics)
    $thead = "<thead><tr><th>Ano</th><th>Repos</th></tr></thead><tbody>"
    foreach ($y in $Metrics.ByYear) {
        $thead += "<tr><td>$($y.Name)</td><td>$($y.Count)</td></tr>"
    }
    return "<table>$thead</tbody></table>"
}

function Get-TopicsTableHtml {
    param($Metrics)
    if (-not $Metrics.TopTopics -or $Metrics.TopTopics.Count -eq 0) {
        return "<p>Nenhum topic encontrado.</p>"
    }
    $thead = "<thead><tr><th>Topic</th><th>Repos</th></tr></thead><tbody>"
    foreach ($t in $Metrics.TopTopics) {
        $thead += "<tr><td>$($t.Key)</td><td>$($t.Value)</td></tr>"
    }
    return "<table>$thead</tbody></table>"
}

function Get-TopStarsTableHtml {
    param($Metrics)
    return Get-SimpleReposTable -Repos $Metrics.TopStars -Col1 "Repo" -Col2 "Stars" -Prop2 "stargazers_count"
}

function Get-TopUpdatedTableHtml {
    param($Metrics)
    return Get-SimpleReposTable -Repos $Metrics.TopUpdated -Col1 "Repo" -Col2 "Atualizado" -Prop2 "updated_at"
}

function Get-TopIssuesTableHtml {
    param($Metrics)
    if (-not $Metrics.TopIssues -or $Metrics.TopIssues.Count -eq 0) {
        return "<p>Nenhum repositório com issues abertas.</p>"
    }
    return Get-SimpleReposTable -Repos $Metrics.TopIssues -Col1 "Repo" -Col2 "Issues" -Prop2 "open_issues_count"
}

function Get-SimpleReposTable {
    param($Repos, [string]$Col1, [string]$Col2, [string]$Prop2)
    $thead = "<thead><tr><th>$Col1</th><th>$Col2</th></tr></thead><tbody>"
    foreach ($r in $Repos) {
        $url = "https://github.com/$($r.full_name)"
        $val = $r.$Prop2
        $thead += "<tr><td><a href='$url' target='_blank' rel='noopener noreferrer'>$($r.name)</a></td><td>$val</td></tr>"
    }
    return "<table>$thead</tbody></table>"
}

#endregion

#region Single Responsibility - Persistência (S)

function Save-Report {
    param([string]$Content, [string]$Path)
    $dir = Split-Path -Parent $Path
    if ($dir -and -not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $Content | Out-File -FilePath $Path -Encoding UTF8
}

#endregion
