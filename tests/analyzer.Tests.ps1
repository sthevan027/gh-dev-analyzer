# Carrega o analyzer (compatível com Pester 3 e 5)
$analyzerPath = Join-Path (Split-Path $PSScriptRoot -Parent) "src\analyzer.ps1"
. $analyzerPath

Describe "Get-AggregatedMetrics" {
    It "calcula total de repos, stars e forks corretamente" {
        $user = [PSCustomObject]@{ login = "test" }
        $repos = @(
            [PSCustomObject]@{
                name               = "repo1"
                full_name          = "test/repo1"
                stargazers_count   = 10
                forks_count        = 2
                open_issues_count  = 1
                private            = $false
                archived           = $false
                fork               = $false
                language           = "Python"
                created_at         = "2024-01-01T00:00:00Z"
                updated_at         = "2024-01-15T00:00:00Z"
                topics             = @("python")
                default_branch     = "main"
            },
            [PSCustomObject]@{
                name               = "repo2"
                full_name          = "test/repo2"
                stargazers_count   = 5
                forks_count        = 1
                open_issues_count  = 0
                private            = $false
                archived           = $false
                fork               = $true
                language           = "Go"
                created_at         = "2024-02-01T00:00:00Z"
                updated_at         = "2024-02-10T00:00:00Z"
                topics             = @()
                default_branch     = "main"
            }
        )
        $metrics = Get-AggregatedMetrics -User $user -Repos $repos
        $metrics.TotalRepos | Should -Be 2
        $metrics.TotalStars | Should -Be 15
        $metrics.TotalForks | Should -Be 3
        $metrics.TotalIssues | Should -Be 1
        $metrics.AvgStars | Should -Be 7.5
        $metrics.PublicRepos | Should -Be 2
        $metrics.ForkRepos | Should -Be 1
    }

    It "retorna AvgStars 0 quando não há repos" {
        $user = [PSCustomObject]@{ login = "test" }
        $repos = @()
        $metrics = Get-AggregatedMetrics -User $user -Repos $repos
        $metrics.AvgStars | Should -Be 0
        $metrics.TotalRepos | Should -Be 0
    }

    It "agrupa linguagens corretamente" {
        $user = [PSCustomObject]@{ login = "test" }
        $repos = @(
            [PSCustomObject]@{ name = "r1"; full_name = "t/r1"; stargazers_count = 0; forks_count = 0; open_issues_count = 0; private = $false; archived = $false; fork = $false; language = "Python"; created_at = "2024-01-01"; updated_at = "2024-01-01"; topics = @(); default_branch = "main" },
            [PSCustomObject]@{ name = "r2"; full_name = "t/r2"; stargazers_count = 0; forks_count = 0; open_issues_count = 0; private = $false; archived = $false; fork = $false; language = "Python"; created_at = "2024-01-01"; updated_at = "2024-01-01"; topics = @(); default_branch = "main" },
            [PSCustomObject]@{ name = "r3"; full_name = "t/r3"; stargazers_count = 0; forks_count = 0; open_issues_count = 0; private = $false; archived = $false; fork = $false; language = "Go"; created_at = "2024-01-01"; updated_at = "2024-01-01"; topics = @(); default_branch = "main" }
        )
        $metrics = Get-AggregatedMetrics -User $user -Repos $repos
        $metrics.LangStats.Count | Should -Be 2
        ($metrics.LangStats | Where-Object { $_.Name -eq "Python" }).Count | Should -Be 2
        ($metrics.LangStats | Where-Object { $_.Name -eq "Go" }).Count | Should -Be 1
    }
}

Describe "Get-TableFromRows" {
    It "gera HTML de tabela corretamente" {
        $headers = @("Col1", "Col2")
        $rows = @("| A | 1 |", "| B | 2 |")
        $result = Get-TableFromRows -Headers $headers -Rows $rows
        $result | Should -Match "<table>"
        $result | Should -Match "<th>Col1</th>"
        $result | Should -Match "<td>A</td>"
        $result | Should -Match "<td>1</td>"
    }
}

Describe "Resolve-ReportPath" {
    It "retorna OutputPath quando fornecido" {
        $path = Resolve-ReportPath -Username "test" -OutputPath "C:\custom\report.html"
        $path | Should -Be "C:\custom\report.html"
    }

    It "retorna caminho com username e data quando OutputPath vazio" {
        $path = Resolve-ReportPath -Username "octocat" -OutputPath ""
        $path | Should -Match "octocat-\d{4}-\d{2}-\d{2}\.html"
        $path | Should -Match "reports"
    }
}

Describe "Save-Report" {
    It "cria arquivo e diretório se não existir" {
        $tempDir = Join-Path $env:TEMP "gh-analyzer-test-$(Get-Random)"
        $subDir = Join-Path $tempDir "subdir"
        $filePath = Join-Path $subDir "test-report.html"
        try {
            Save-Report -Content "<html><body>Test</body></html>" -Path $filePath
            Test-Path $filePath | Should -Be $true
            (Get-Content $filePath -Raw) | Should -Match "<html>"
        } finally {
            Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Describe "Script load" {
    It "analyzer.ps1 carrega sem erro" {
        $path = Join-Path (Split-Path $PSScriptRoot -Parent) "src\analyzer.ps1"
        { . $path } | Should -Not -Throw
    }
}
