# GH Dev Analyzer

CLI que analisa um perfil do GitHub e gera um relatório HTML detalhado.

## Arquitetura do projeto

```text
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
│  ├─ metrics.md            # Documentação das métricas
│  └─ GETTING_STARTED.md    # Guia de início rápido
│
├─ src
│  └─ analyzer.ps1          # Módulo de análise (lógica principal)
│
├─ tests
│  └─ analyzer.Tests.ps1    # Testes Pester
├─ reports                  # Relatórios HTML gerados (padrão)
│  └─ {username}-{data}.html
│
├─ .github
│  ├─ ISSUE_TEMPLATE/       # Templates para issues
│  │  ├─ bug_report.md
│  │  ├─ feature_request.md
│  │  └─ config.yml
│  ├─ workflows/
│  │  ├─ ci.yml              # CI: PSScriptAnalyzer, Pester, smoke test, coverage
│  │  ├─ release.yml         # Release automático em tags v*
│  │  ├─ codeql.yml          # Análise de segurança
│  │  ├─ pr-validation.yml   # Validação de CHANGELOG em PRs
│  │  ├─ docs.yml            # Lint de Markdown
│  │  ├─ scheduled.yml       # Smoke test agendado (diário)
│  │  ├─ issues-check.yml    # Relatório de issues abertas
│  │  └─ ci-failure-issue.yml # Cria issue quando o CI falha
│  ├─ dependabot.yml         # Atualização automática de GitHub Actions
│  ├─ PULL_REQUEST_TEMPLATE.md
│  └─ FUNDING.yml
├─ README.md
├─ LICENSE
├─ CONTRIBUTING.md
├─ CHANGELOG.md
├─ CODE_OF_CONDUCT.md
├─ SECURITY.md
└─ .gitignore
```

## Features

- Métricas de perfil
- Análise de repositórios
- Estatísticas de linguagens
- Insights de atividade
- Developer score

## Documentação

- [Guia de início rápido](docs/GETTING_STARTED.md) — instalação e primeiro uso
- [Métricas](docs/metrics.md) — documentação das métricas coletadas

## CI/CD

| Workflow | Gatilho | Descrição |
|----------|---------|-----------|
| **CI** | push/PR em main/master | PSScriptAnalyzer; Pester com coverage; smoke test; upload para Codecov |
| **Release** | push de tag `v*` | Cria GitHub Release com conteúdo do CHANGELOG |
| **CodeQL** | push/PR + semanal | Análise de segurança |
| **PR Validation** | PR que altera src/ ou scripts/ | Verifica se CHANGELOG foi atualizado |
| **Docs** | push/PR em docs/ ou *.md | Lint de Markdown |
| **Scheduled** | diário (12h) + manual | Smoke test da API do GitHub |
| **Issues Check** | seg–sex 8h + manual | Relatório de issues abertas e antigas (30+ dias sem atualização) |
| **CI Failure → Issue** | quando CI falha | Cria issue automaticamente para rastrear a correção |

O **Dependabot** atualiza as GitHub Actions semanalmente (segundas).

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
powershell scripts/analyze-github.ps1 -Username octocat -OutputPath report.html
```

### Nome automático do arquivo

Sem `-OutputPath`, o relatório é salvo em `reports/` com o padrão **username + data**:

```text
reports/octocat-2026-03-05.html
```
