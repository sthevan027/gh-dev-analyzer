# Contribuindo com o GH Dev Analyzer

Obrigado por considerar contribuir! 🎉

## Como contribuir

1. **Fork** o repositório
2. **Clone** seu fork
3. Crie uma **branch** para sua feature (`git checkout -b feature/minha-feature`)
4. **Commit** suas alterações
5. **Push** para a branch
6. Abra um **Pull Request**

## Estrutura do projeto

Consulte o [README.md](README.md) para a arquitetura completa.

## Desenvolvimento

- Scripts PowerShell: siga as convenções do [PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer)
- Documentação: edite os arquivos em `docs/`
- Exemplos: adicione em `examples/`

### Testes locais

Requer **Pester 5** e **PowerShell 7**:

```powershell
Install-Module -Name Pester -Force -Scope CurrentUser -AllowClobber
Install-Module -Name PSScriptAnalyzer -Force -Scope CurrentUser -AllowClobber
Invoke-Pester -Path ./tests -PassThru
Invoke-ScriptAnalyzer -Path ./src -Recurse
```

## Reportar bugs

Abra uma issue descrevendo o problema, ambiente e passos para reproduzir.

## Sugerir features

Issues com a tag `enhancement` são bem-vindas. Descreva o caso de uso e o comportamento esperado.

## Roadmap

- ✅ Relatório HTML
- Developer score (algoritmo de pontuação)
- Integração GraphQL API
- Dashboard web
