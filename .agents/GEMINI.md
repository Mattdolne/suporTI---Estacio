# Diretrizes e Contexto do Projeto - Gemini / Antigravity

Este repositório contém a ferramenta **suporTI---Estacio** para suporte técnico Nível 1 na Estácio de Sá - Campus Resende.

Para a documentação completa de arquitetura, parâmetros de módulos e instruções de retomada de tarefas, consulte o arquivo oficial de contexto:
👉 [GEMINI.md](../GEMINI.md)

## Regras de Versionamento e Atualização
Sempre que qualquer código ou funcionalidade for alterado/adicionado:
1. **Incrementar Versão e Data (SemVer)**:
   - Atualizar a função `Sobre` em `menu.ps1` (`Versao:` e `Data da ultima atualizacao:`).
   - Atualizar a badge `![Versão]` e a seção Sobre em `README.md`.
   - Atualizar os cabeçalhos de versão em `GEMINI.md`.

## Regras de Automação Git
2. Sempre que a documentação (`README.md`, `GEMINI.md`) ou código em `funcoes/` for alterado, efetue o commit e o push automático para a branch `main`:
   ```bash
   git add .
   git commit -m "docs/feat/fix: mensagem explicativa (vX.X.X)"
   git push origin main
   ```
