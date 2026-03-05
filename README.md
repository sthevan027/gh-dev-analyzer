# GH Dev Analyzer

CLI que analisa um perfil do GitHub e gera um relatório detalhado.

## Arquitetura do projeto

```
gh-dev-analyzer
│
├─ scripts
│  └─ analyze-github.ps1    # Script principal de execução
│
├─ examples
│  └─ example-report.md     # Exemplo de relatório gerado
│
├─ docs
│  └─ metrics.md            # Documentação das métricas
│
├─ src
│  └─ analyzer.ps1          # Módulo de análise (lógica principal)
│
├─ README.md
├─ LICENSE
├─ CONTRIBUTING.md
└─ .gitignore
```

## Features

- Métricas de perfil
- Análise de repositórios
- Estatísticas de linguagens
- Insights de atividade
- Developer score

## Requisitos

- GitHub CLI (`gh`)
- PowerShell

## Uso

```powershell
# Analisar seu próprio perfil (requer gh auth login)
powershell scripts/analyze-github.ps1

# Analisar outro usuário
powershell scripts/analyze-github.ps1 -Username octocat

# Salvar em arquivo
powershell scripts/analyze-github.ps1 -Username octocat -OutputPath relatorio.md
```
