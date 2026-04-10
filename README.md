# 🛠️ Ferramenta de Suporte TI - Campus Resende

![PowerShell](https://img.shields.io/badge/PowerShell-%E2%89%A55.1-blue?logo=powershell)
![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D6?logo=windows)
![Versão](https://img.shields.io/badge/Vers%C3%A3o-1.1-brightgreen)

Um "canivete suíço" em PowerShell desenvolvido para otimizar, automatizar e padronizar os atendimentos de suporte técnico de Nível 1 no ambiente acadêmico.

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
```

🚀 Funcionalidades por Módulo

🧹 1. Limpeza

Foco em liberação de espaço e privacidade, gerando arquivo de log em C:\registrolimpezapreventiva.txt.

    Limpeza Rápida: Esvazia %TEMP%, C:\Windows\Temp e a Lixeira do sistema de forma segura (tratando erros de arquivos em uso).

    Limpeza Completa: Remove os itens da limpeza rápida e varre pastas de perfis de usuário (Downloads, Documents, etc.), respeitando uma whitelist de extensões no Desktop (.lnk, .url, .website). Limpa também o cache do Google Chrome e Microsoft Edge (não rode em máquina administrativa, pois apaga arquivos de usuários).

    Opções integradas para desligar a máquina automaticamente após o término.

📊 2. Auditoria

Coleta dados de Hardware, Rede e Sistema Operacional sem depender de ferramentas de terceiros.

    Dados coletados: Hostname, Domínio, Versão/Build do Windows, Data de Formatação, Serial Number da BIOS, CPU, RAM total, Espaço em Disco (Total/Usado), IP e MAC Address.

    Formatos de Exportação: * Visualização direta no Terminal.

        Exportação para TXT (Leitura rápida).

        Exportação para CSV (Integração com Excel/Sistemas de Gestão).

        Exportação para XML (Armazenamento estruturado).

        Nota: Todos os relatórios recebem carimbo de Data/Hora e são salvos automaticamente no Desktop do usuário.

🔧 3. Manutenção

Solução rápida para os problemas mais comuns de infraestrutura e SO.

    Teste de Rede Avançado: Valida conectividade externa (Ping), resolução DNS, disponibilidade de Portais Institucionais HTTP (SIA e SAVA) e estima a taxa de Download real via CDN (Megabits e Megabytes por segundo).

    Correção do Sistema: Executa rotina combinada de verificação de integridade (SFC /scannow) e reparo de imagem (DISM /RestoreHealth).

    Reset do Windows Update: Para serviços críticos (wuauserv, bits, cryptsvc), limpa o cache corrompido (DataStore e Download) e reinicia os serviços.

    Limpeza de Updates Antigos: Limpa instaladores de cache antigos do Windows Update para liberar espaço em disco (pode liberar muito espaço, mas também impede rollback de versões antigas de updates - use com cautela).

⚙️ Pré-requisitos e Execução

    O script foi projetado para rodar nativamente no Windows 10 e Windows 11.

    É obrigatória a execução com Privilégios de Administrador (o próprio script fará a validação e bloqueará a execução caso o técnico não seja admin).

🏃 Como usar

Para evitar bloqueios de script, rode como administrador do .bat Executar. Além de tratar como executável, este bat roda uma camada adicional de prompt de comando que permite que os scripts .ps1 funcionem sem restrições comuns. 
