# GH Dev Analyzer

CLI que analisa um perfil do GitHub e gera um relatório HTML detalhado.

## Arquitetura do projeto

```
gh-dev-analyzer
│
├─ scripts
│  └─ analyze-github.ps1    # Script principal de execução
│
├─ examples
│  ├─ exemplo-01-iniciante.html    # Exemplo: perfil iniciante
│  ├─ exemplo-02-intermediario.html # Exemplo: perfil intermediário
│  ├─ exemplo-03-avancado.html     # Exemplo: perfil avançado
│  └─ README.md
│
├─ docs
│  └─ metrics.md            # Documentação das métricas
│
├─ src
│  └─ analyzer.ps1          # Módulo de análise (lógica principal)
│
├─ reports                  # Relatórios HTML gerados (padrão)
│  └─ {username}-{data}.html
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
# Gera reports/{seu-login}-{data}.html
powershell scripts/analyze-github.ps1

# Analisar outro usuário
powershell scripts/analyze-github.ps1 -Username octocat

# Salvar em caminho específico
powershell scripts/analyze-github.ps1 -Username octocat -OutputPath C:\relatorios\octocat.html
```

O relatório HTML usa o nome `{username}-{yyyy-MM-dd}.html` por padrão na pasta `reports/`.
