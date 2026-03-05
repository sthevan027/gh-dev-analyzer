# Métricas do GH Dev Analyzer

Documentação das métricas coletadas na análise de perfis GitHub.

## Métricas de perfil

| Métrica | Descrição | Fonte |
|---------|-----------|-------|
| Seguidores | Número de seguidores do usuário | `gh api users/{username}` |
| Seguindo | Número de usuários que o usuário segue | `gh api users/{username}` |
| Repositórios | Total de repositórios públicos | `gh api users/{username}/repos` |
| Conta criada | Data de criação da conta | `gh api users/{username}` |

## Métricas de contribuição

| Métrica | Descrição | Fonte |
|---------|-----------|-------|
| Contribuições (ano) | Total de contribuições no último ano | GraphQL API |
| Commits (30 dias) | Commits nos últimos 30 dias | `gh api` + eventos |
| PRs abertos | Pull requests abertos pelo usuário | `gh pr list --author` |
| Issues abertas | Issues abertas pelo usuário | `gh issue list --author` |

## Métricas de repositório

| Métrica | Descrição |
|---------|-----------|
| Linguagens | Distribuição por linguagem de programação |
| Stars | Total de estrelas nos repositórios |
| Forks | Total de forks |
| Tamanho | Linhas de código (aproximado) |

## Developer Score

Score composto (0–100) baseado em:
- Atividade recente
- Diversidade de projetos
- Engajamento da comunidade (stars, forks)
- Consistência de contribuições

---

*Em desenvolvimento.*
