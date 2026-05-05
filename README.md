# Ferramenta de Suporte TI - Campus Resende

![PowerShell](https://img.shields.io/badge/PowerShell-%3E%3D%205.1-blue)
![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D4)
![Versão](https://img.shields.io/badge/Vers%C3%A3o-1.2-green)

---
Um canivete suico em PowerShell desenvolvido para otimizar, automatizar e padronizar os atendimentos de suporte tecnico de Nivel 1 no ambiente academico.

## Objetivo

Reduzir o tempo gasto com rotinas repetitivas de troubleshooting, limpeza de disco, coleta de inventario e correcao de sistema operacional, garantindo que os procedimentos sejam executados de forma segura e gerem logs de auditoria.

---

## Estrutura do Projeto

A ferramenta foi construida com uma arquitetura modular. O menu.ps1 atua como o roteador central, carregando as funcoes de scripts isolados na pasta funcoes.

📦 suporte-ti
 ┣ menu.ps1               # Script principal e menu interativo
 ┗ funcoes
    ┣ limpeza.ps1         # Modulo de limpeza de disco e cache
    ┣ auditoria.ps1       # Modulo de coleta de inventario
    ┗ manutencao.ps1      # Modulo de diagnostico e reparo de SO

## Funcionalidades por Modulo

1. Limpeza

Foco em liberacao de espaco e privacidade, gerando arquivo de log em C:\registrolimpezapreventiva.txt.

    Limpeza Rapida: Esvazia %TEMP%, C:\Windows\Temp e a Lixeira do sistema de forma segura (tratando erros de arquivos em uso).

    Limpeza Completa: Remove os itens da limpeza rapida e varre pastas de perfis de usuario (Downloads, Documents, etc.), respeitando uma whitelist de extensoes no Desktop (.lnk, .url, .website). Limpa tambem o cache do Google Chrome e Microsoft Edge (nao rode em maquina administrativa, pois apaga arquivos de usuarios).

    Opcoes integradas para desligar a maquina automaticamente apos o termino.

2. Auditoria

Coleta dados de Hardware, Rede e Sistema Operacional sem depender de ferramentas de terceiros.

    Dados coletados: Hostname, Dominio, Versao/Build do Windows, Data de Formatacao, Serial Number da BIOS, CPU, RAM total, Espaco em Disco (Total/Usado), IP e MAC Address.

    Formatos de Exportacao: 
    - Visualizacao direta no Terminal.
    - Exportacao para TXT (Leitura rapida).
    - Exportacao para CSV (Integracao com Excel/Sistemas de Gestao).
    - Exportacao para XML (Armazenamento estruturado).

    Nota: Todos os relatorios recebem carimbo de Data/Hora e sao salvos automaticamente no Desktop do usuario.

3. Manutencao

Solucao rapida para os problemas mais comuns de infraestrutura e SO.

    Teste de Rede Avancado: Valida conectividade externa (Ping), resolucao DNS, disponibilidade de Portais Institucionais HTTP (SIA e SAVA) e estima a taxa de Download real via CDN (Megabits e Megabytes por segundo).

    Correcao do Sistema: Executa rotina combinada de verificacao de integridade (SFC /scannow) e reparo de imagem (DISM /RestoreHealth).

    Reset do Windows Update: Para servicos criticos (wuauserv, bits, cryptsvc), limpa o cache corrompido (DataStore e Download) e reinicia os servicos.

    Limpeza de Updates Antigos: Limpa instaladores de cache antigos do Windows Update para liberar espaco em disco (pode liberar muito espaco, mas tambem impede rollback de versoes antigas de updates - use com cautela).

    Listar e resetar senha de usuarios locais.

    Reiniciar adaptador de rede.

    Verificar e corrigir erros de disco.

    Atualizar e verificar politicas de grupo - GPOs

    Instalar RSAT - Inicia verificação se a máquina está dentro de domínio para prosseguir com a configuração

## Pre-requisitos e Execucao

    O script foi projetado para rodar nativamente no Windows 10 e Windows 11.
    E obrigatoria a execucao com Privilegios de Administrador (o proprio script fara a validacao e bloqueara a execucao caso o tecnico nao seja admin).

## Como usar

Para evitar bloqueios de script, rode como administrador do .bat Executar. Alem de tratar como executavel, este bat roda uma camada adicional de prompt de comando que permite que os scripts .ps1 funcionem sem restricoes comuns.
