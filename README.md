# 🛠️ Ferramenta de Suporte TI — Campus Resende

![PowerShell](https://img.shields.io/badge/PowerShell-%3E%3D%205.1-blue?style=for-the-badge&logo=powershell)
![Windows](https://img.shields.io/badge/Windows-10%20%7C%2011-0078D4?style=for-the-badge&logo=windows)
![Versão](https://img.shields.io/badge/Vers%C3%A3o-1.3-green?style=for-the-badge)
![Instituição](https://img.shields.io/badge/Est%C3%A1cio-Resende-red?style=for-the-badge)
![Licença](https://img.shields.io/badge/Licen%C3%A7a-MIT-orange?style=for-the-badge)

Um **canivete suíço modular em PowerShell** desenvolvido para otimizar, automatizar e padronizar as rotinas de suporte técnico de Nível 1 e Nível 2 nos ambientes acadêmicos e administrativos do **Campus Resende (Estácio de Sá)**.

---

## 📋 Tabela de Conteúdo

- [✨ Visão Geral](#-visão-geral)
- [🏗️ Estrutura do Projeto](#️-estrutura-do-projeto)
- [⚙️ Módulos e Funcionalidades](#️-módulos-e-funcionalidades)
  - [🧹 1. Módulo de Limpeza](#-1-módulo-de-limpeza)
  - [📊 2. Módulo de Auditoria](#-2-módulo-de-auditoria)
  - [🛠️ 3. Módulo de Manutenção](#-3-módulo-de-manutenção)
- [🔒 Pré-requisitos e Permissões](#-pré-requisitos-e-permissões)
- [🚀 Como Executar](#-como-executar)
- [📝 Logs e Relatórios Gerados](#-logs-e-relatórios-gerados)
- [⚠️ Avisos de Segurança](#️-avisos-de-segurança)
- [🤝 Contribuição e Manutenção](#-contribuição-e-manutenção)
- [👤 Autoria e Créditos](#-autoria-e-créditos)

---

## ✨ Visão Geral

Nas operações de suporte de TI em campi universitários, técnicos enfrentam repetidamente demandas como: acúmulo de arquivos temporários em laboratórios, lentidão por excesso de perfis de alunos inativos, diagnóstico de falhas de rede, redefinição de senhas locais e coleta de informações de hardware para inventário.

O **suporTI---Estacio** unifica essas soluções em uma interface de linha de comando (CLI) interativa, rápida e amigável. Ele elimina scripts soltos e comandos manuais, garantindo que o atendimento seja padronizado, seguro e auditável.

---

## 🏗️ Estrutura do Projeto

O projeto adota uma arquitetura modular limpa. O script `menu.ps1` atua como o orquestrador central e carrega dinamicamente as funções isoladas situadas no diretório `funcoes/`.

```text
📦 suporTI---Estacio
 ┣ 📜 Executar.bat             # Atalho de inicialização rápida em modo desenvolvimento
 ┣ 📜 GerarExecutavel.bat      # Automação de compilação do executável de produção (.exe)
 ┣ 📜 Gerar-Executavel.ps1     # Engine de empacotamento standalone e compilação C# (csc.exe)
 ┣ 📜 menu.ps1                  # Interface CLI interativa, roteador e validação de Admin
 ┣ 📜 GEMINI.md                 # Manual de contexto técnico completo para assistentes de IA
 ┣ 📜 README.md                 # Documentação oficial do projeto
 ┗ 📁 funcoes/
    ┣ 📜 limpeza.ps1           # Módulo de higienização de disco, lixeira e perfis
    ┣ 📜 auditoria.ps1         # Módulo de inventário de hardware, rede e SO
    ┗ 📜 manutencao.ps1        # Módulo de reparo de sistema, diagnóstico de rede e AD
```

---

## ⚙️ Módulos e Funcionalidades

### 🧹 1. Módulo de Limpeza (`funcoes/limpeza.ps1`)

Focado na liberação de espaço em disco e higienização do sistema.

* **Limpeza Rápida**: Esvazia pastas temporárias do usuário (`%TEMP%`), do sistema (`C:\Windows\Temp`), diretórios de cache temporário de todos os usuários (`AppData\Local\Temp`) e esvazia a Lixeira (`C:\$Recycle.Bin`).
* **Limpeza Completa**: Inclui todos os passos da Limpeza Rápida e realiza a higienização de pastas pessoais (`Documents`, `Downloads`, `Pictures`, `Videos`, `Favorites`, `Links`, `Searches`) de todos os perfis.
  > 🛡️ **Proteção do Desktop**: Limpa arquivos soltos na Área de Trabalho, mas preserva atalhos (`.lnk`, `.url`, `.website`). Limpa também os caches do Google Chrome e Microsoft Edge.
* **Limpeza de Perfis Inativos (>10 dias)**: Identifica e remove perfis de usuários locais/domínio não carregados que não registram utilização há mais de 10 dias via CIM (`Win32_UserProfile`), liberando dezenas de gigabytes em computadores de laboratório.
* **Limpeza de Perfis Secundários do Chrome e Edge**: Varre as instalações de navegadores de todos os usuários e exclui todos os perfis adicionais (`Profile 1`, `Profile 2`, etc.), incluindo contas sincronizadas, **preservando o 1º perfil principal (`Default`)**.
* **Opções com Desligamento**: Permite agendar o desligamento automático do computador (`shutdown /s /t 5`) imediatamente após a conclusão da limpeza.

---

### 📊 2. Módulo de Auditoria (`funcoes/auditoria.ps1`)

Coleta dados completos de hardware, rede e sistema operacional sem necessidade de softwares externos.

* **Informações Coletadas**:
  * **Sistema**: Hostname, Domínio, Versão e Build do Windows, Data de Formatação/Instalação.
  * **Hardware**: Número de Série (BIOS), Processador, Memória RAM Total (GB), Capacidade Total e Espaço Livre do Disco `C:`.
  * **Rede**: Endereço IP IPv4 e MAC Address.
* **Formatos de Exportação** (Salvos automaticamente na Área de Trabalho):
  * 🖥️ **Terminal**: Exibição formatada no próprio console.
  * 📄 **TXT**: Relatório textual legível (`Auditoria_<HOSTNAME>.txt`).
  * 📊 **CSV**: Arquivo estruturado separado por `;` e UTF-8 para análise no Excel (`Auditoria_<HOSTNAME>.csv`).
  * 🧩 **XML**: Exportação de objeto estruturado via `Export-Clixml` (`Auditoria_<HOSTNAME>.xml`).

---

### 🛠️ 3. Módulo de Manutenção (`funcoes/manutencao.ps1`)

Ferramentas avançadas de diagnóstico de rede, restauração de serviços do Windows e administração básica.

1. **Teste de Rede Completo**:
   * Teste de Conectividade Externa (Ping para `8.8.8.8`).
   * Teste de Resolução de Nomes (DNS para `google.com`).
   * Teste HTTP de disponibilidade dos portais institucionais: **SIA**, **SAVA** e **ADP**.
   * Exibição das interfaces de rede ativas e seus IPs.
2. **Correção de Erros do Sistema**:
   * Executa a rotina de verificação de arquivos corrompidos `sfc /scannow`.
   * Executa a restauração da imagem do Windows `Repair-WindowsImage -Online -RestoreHealth` (DISM).
3. **Reset do Windows Update**:
   * Interrompe os serviços `wuauserv`, `bits` e `cryptsvc`, apaga os arquivos de cache de download em `C:\Windows\SoftwareDistribution` e reinicia os serviços.
4. **Limpeza de Updates Antigos**:
   * Apaga instaladores de atualizações armazenados no cache para liberar espaço.
5. **Reset de Senha de Usuário Local**:
   * Lista usuários cadastrados na máquina (`Get-LocalUser`) e permite redefinir a senha com campo mascarado (`Read-Host -AsSecureString`).
6. **Reiniciar Adaptador de Rede**:
   * Lista adaptadores ativos e realiza o ciclo `Disable-NetAdapter` / `Enable-NetAdapter`.
7. **Verificação e Correção de Disco (`chkdsk`)**:
   * Leitura rápida em modo somente leitura ou agendamento de verificação profunda no boot (`chkdsk C: /f /r`).
8. **Atualizar Diretivas de Grupo (GPO)**:
   * Força a atualização com `gpupdate /force` e valida o canal de confiança no domínio (`Test-ComputerSecureChannel`).
9. **Instalação do RSAT (Remote Server Administration Tools)**:
   * Valida se o computador está em domínio (`CORP`/`ACAD`) e instala os módulos de Active Directory e Gerenciamento de GPO via `Add-WindowsCapability`.
10. **Redefinir Aparência do Windows para o Padrão**:
   * Restaura o tema original do Windows (Modo Claro para sistema e apps, barra de tarefas com layout padrão, cores de destaque nativas e transparência).
   * **Preserva o plano de fundo/wallpaper** do usuário sem alterações.

---

## 🔒 Pré-requisitos e Permissões

* **Sistema Operacional**: Windows 10 ou Windows 11 (64-bit).
* **PowerShell**: Versão 5.1 ou superior (nativo no Windows 10/11).
* **Privilégios**: **Administrador**. O script valida automaticamente se a sessão possui elevação de privilégio. Se executado sem Admin, o programa é interrompido por segurança.

---

## 🚀 Como Executar

### Método Recomendado (Via Script Batch)

1. Faça o download ou clone o repositório em uma pasta local:
   ```cmd
   git clone https://github.com/Mattdolne/suporTI---Estacio.git
   ```
2. Clique com o **botão direito** no arquivo `Executar.bat` e selecione **"Executar como Administrador"**.
3. O script irá bypassar a política de execução restrita do PowerShell e abrir o menu principal automaticamente.

### Método Alternativo (Via PowerShell Direct)

1. Abra o PowerShell como **Administrador**.
2. Navegue até a pasta do projeto:
   ```powershell
   cd "C:\caminho\para\suporTI---Estacio"
   ```
3. Execute o script definindo a política de execução para a sessão:
   ```powershell
   powershell -ExecutionPolicy Bypass -File .\menu.ps1
   ```

---

## 📝 Logs e Relatórios Gerados

| Arquivo / Destino | Módulo Gerador | Descrição |
| :--- | :--- | :--- |
| `C:\registrolimpezapreventiva.txt` | Limpeza | Registro detalhado de cada arquivo/pasta limpa, quantidade de itens e megabytes liberados. |
| `Desktop\Auditoria_<HOSTNAME>.csv` | Auditoria | Relatório estruturado em CSV (delimitado por `;`) contendo dados de hardware, rede e SO. |
| `Desktop\Auditoria_<HOSTNAME>.xml` | Auditoria | Objeto de inventário exportado em formato XML. |
| `Desktop\Auditoria_<HOSTNAME>.txt` | Auditoria | Relatório legível em texto simples. |

---

## ⚠️ Avisos de Segurança

* **Limpeza Completa**: Apaga arquivos pessoais nas pastas padrão de usuário (`Downloads`, `Documents`, etc.). **Não execute em máquinas administrativas sem backup prévio.**
* **Limpeza de Perfis Inativos**: Apaga permanentemente pastas de perfis de usuário inativos há mais de 10 dias. Certifique-se de que nenhum dado crítico esteja armazenado localmente nestes perfis.
* **Limpeza de Cache do Windows Update**: Impede a realização de *rollback* (desinstalação) de atualizações instaladas recentemente.

---

## 🤝 Contribuição e Manutenção

Para contribuir com o projeto ou adaptar para a sua unidade:

1. Consulte o guia técnico avançado em [`GEMINI.md`](GEMINI.md).
2. Adicione novas funções nos scripts dentro da pasta `funcoes/`.
3. Mantenha os padrões de nomenclatura PowerShell (ex: `Verbo-Substantivo`) e tratamento de exceções com `try/catch`.
4. Garanta a codificação UTF-8 nos arquivos editados.

---

## 👤 Autoria e Créditos

* **Desenvolvedor**: Mattheus Macedo
* **Unidade**: Estácio de Sá — Campus Resende
* **Frase**: *"Educar para Transformar!"*
* **Licença**: Este projeto é distribuído sob a licença MIT. Sinta-se à vontade para utilizar, modificar e distribuir.
