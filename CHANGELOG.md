# Changelog

Todas as mudanças relevantes do projeto são documentadas neste arquivo.

O formato é baseado em [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/),
e o projeto adere ao [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [Não publicado]

### Adicionado

- Relatório HTML com tema escuro (estilo GitHub)
- Nome automático do arquivo: `{username}-{yyyy-MM-dd}.html`
- Métricas: perfil, repositórios, linguagens, topics, por ano
- Suporte a análise de usuário autenticado ou outro usuário via `-Username`
- Parâmetro `-OutputPath` para salvar em caminho customizado
- Estrutura SOLID no módulo de análise
- Exemplos: perfil iniciante, intermediário e avançado

### Alterado

- Output alterado de Markdown para HTML

## [1.0.0] - 2026-03-05

### Adicionado

- Versão inicial do GH Dev Analyzer
- Integração com GitHub CLI (`gh api`)
- Métricas de perfil (seguidores, repos, gists, etc.)
- Métricas gerais (stars, forks, issues, arquivados)
- Tabela completa de repositórios
- Estatísticas por linguagem e por ano de criação
- Top 15 topics
- Top repos por stars, atualização e issues
