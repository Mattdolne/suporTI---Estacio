# 🛠️ Ferramenta de Suporte TI - Campus Resende

![PowerShell](https://img.shields.io/badge/PowerShell-%E2%89%A55.1-blue?logo=powershell)
![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6?logo=windows)
![Versão](https://img.shields.io/badge/Vers%C3%A3o-1.1-brightgreen)

Um "canivete suíço" em PowerShell desenvolvido para otimizar, automatizar e padronizar os atendimentos de suporte técnico de Nível 1 e 2 no ambiente acadêmico e administrativo.

## 🎯 Objetivo
Reduzir o tempo gasto com rotinas repetitivas de troubleshooting, limpeza de disco, coleta de inventário e correção de sistema operacional, garantindo que os procedimentos sejam executados de forma segura e gerem logs de auditoria.

---

## 📂 Estrutura do Projeto

A ferramenta foi construída com uma arquitetura modular. O `menu.ps1` atua como o roteador central, carregando as funções de scripts isolados na pasta `funcoes`.

```text
📦 suporte-ti
 ┣ 📜 menu.ps1               # Script principal e menu interativo
 ┗ 📂 funcoes
    ┣ 📜 limpeza.ps1         # Módulo de limpeza de disco e cache
    ┣ 📜 auditoria.ps1       # Módulo de coleta de inventário
    ┗ 📜 manutencao.ps1      # Módulo de diagnóstico e reparo de SO