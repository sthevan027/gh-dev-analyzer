# Guia de início rápido

Passo a passo para começar a usar o GH Dev Analyzer.

## Pré-requisitos

### 1. PowerShell

O script funciona em **PowerShell 5.1** (Windows) ou **PowerShell 7+** (cross-platform).

Verifique sua versão:

```powershell
$PSVersionTable.PSVersion
```

### 2. GitHub CLI (gh)

O GH Dev Analyzer usa o `gh` para acessar a API do GitHub.

**Instalação:**

| Plataforma | Comando / Link |
|------------|----------------|
| Windows (winget) | `winget install GitHub.cli` |
| Windows (Scoop) | `scoop install gh` |
| macOS | `brew install gh` |
| Linux | [Instruções oficiais](https://cli.github.com/) |

**Verificar instalação:**

```powershell
gh --version
```

### 3. Autenticação no GitHub

Para analisar perfis (incluindo o seu), faça login:

```powershell
gh auth login
```

Siga o fluxo interativo (escolha HTTPS ou SSH, autenticação via navegador ou token).

**Verificar autenticação:**

```powershell
gh auth status
```

## Instalação

### Opção A: Clone do repositório

```powershell
git clone https://github.com/seu-usuario/gh-dev-analyzer.git
cd gh-dev-analyzer
```

### Opção B: Download manual

1. Baixe o projeto (ZIP ou clone)
2. Extraia em uma pasta
3. Navegue até a pasta no terminal

## Primeiro uso

### Analisar seu próprio perfil

```powershell
powershell scripts/analyze-github.ps1
```

O relatório será gerado em `reports/{seu-login}-{data}.html`.

### Analisar outro usuário

```powershell
powershell scripts/analyze-github.ps1 -Username octocat
```

### Salvar em um caminho específico

```powershell
powershell scripts/analyze-github.ps1 -Username octocat -OutputPath C:\relatorios\meu-relatorio.html
```

## Abrindo o relatório

O arquivo HTML pode ser aberto em qualquer navegador:

- Duplo clique no arquivo
- Ou: `start reports/octocat-2026-03-05.html` (Windows)
- Ou: `xdg-open reports/octocat-2026-03-05.html` (Linux)

## Próximos passos

- Veja os [exemplos](../examples/) de relatórios
- Leia a [documentação de métricas](metrics.md)
- Consulte o [README](../README.md) para mais opções
