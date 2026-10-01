# GEMINI.md — Guia de Contexto e Instruções Técnicas para IA

Este documento contém o contexto técnico completo, a arquitetura, a especificação das rotinas e as diretrizes de desenvolvimento do projeto **suporTI---Estacio**. Ele serve como base autoritativa de conhecimento para assistentes de Inteligência Artificial (Gemini / Antigravity) e novos desenvolvedores que venham a manter ou evoluir a ferramenta.

---

## 📌 1. Visão Geral do Projeto

* **Nome do Projeto**: Ferramenta de Suporte TI - Campus Resende (`suporTI---Estacio`)
* **Desenvolvedor / Mantenedor**: Mattheus Macedo
* **Instituição**: Estácio de Sá — Campus Resende
* **Versão Atual**: 1.2 (Atualizado em 2026)
* **Linguagem Principal**: PowerShell 5.1+ & Windows Batch Script
* **Repositório GitHub**: [Mattdolne/suporTI---Estacio](https://github.com/Mattdolne/suporTI---Estacio.git)

### 🎯 Propósito
O `suporTI---Estacio` é um "canivete suíço" em PowerShell projetado especificamente para otimizar, automotizar e padronizar os atendimentos de suporte técnico de Nível 1 e Nível 2 na infraestrutura acadêmica e administrativa do Campus Resende. 

A ferramenta resolve gargalos operacionais diários, tais como:
* Acúmulo de arquivos temporários e perfis de usuários inativos em laboratórios de informática.
* Coleta manual e demorada de informações de inventário (hardware, sistema e rede) para chamados.
* Diagnósticos repetitivos de problemas de conectividade, erros do Windows Update, corrupção de sistema de arquivos e ingressos no domínio (`CORP` / `ACAD`).

---

## 🏗️ 2. Arquitetura do Sistema e Estrutura de Pastas

O projeto adota uma **arquitetura modular**. O arquivo `menu.ps1` atua como o orquestrador principal e roteador da interface CLI (Command Line Interface), enquanto a lógica de negócios é segregada em módulos funcionais localizados no diretório `funcoes/`.

### 📂 Estrutura do Repositório

```text
C:\Users\mattheus.pereira\OneDrive - Corporativo\TI\Programas\suporte\suporTI---Estacio
├── Executar.bat             # Script de inicialização (Bypass ExecutionPolicy)
├── menu.ps1                  # Menu principal, roteamento e validação de privilégios
├── GEMINI.md                 # Guia técnico de contexto para IA (este arquivo)
├── README.md                 # Documentação pública do repositório
└── funcoes/
    ├── limpeza.ps1           # Módulo de limpeza preventiva, lixeira e remoção de perfis
    ├── auditoria.ps1         # Módulo de coleta de inventário e exportação de dados
    └── manutencao.ps1        # Módulo de diagnósticos de rede, reparo de SO e ferramentas AD
```

### 🔗 Fluxo de Execução e Carregamento

1. **Inicialização pelo Usuário**:
   O técnico executa `Executar.bat` com privilégios de Administrador.
2. **Ignorar Política de Execução**:
   O `Executar.bat` define o diretório atual via `cd /d "%~dp0"` e invoca `powershell.exe -ExecutionPolicy Bypass -File ".\menu.ps1"`.
3. **Carregamento por Dot-Sourcing**:
   Ao iniciar, `menu.ps1` descobre o caminho base do projeto e importa dinamicamente os três scripts da pasta `funcoes/` utilizando *dot-sourcing*:
   ```powershell
   . "$basePath\funcoes\limpeza.ps1"
   . "$basePath\funcoes\auditoria.ps1"
   . "$basePath\funcoes\manutencao.ps1"
   ```
4. **Validação de Segurança (Admin Check)**:
   A função `Test-Admin` em `menu.ps1` verifica se o processo possui a role `[Security.Principal.WindowsBuiltInRole]::Administrator`. Se falso, a execução é abortada.
5. **Validação de Comandos**:
   O script verifica se as funções principais (`Limpeza`, `Auditoria`, `Manutencao`) estão presentes na memória da sessão (`Get-Command`).

---

## 🛠️ 3. Detalhamento dos Módulos e Funcionalidades

### 🧹 3.1. Módulo de Limpeza (`funcoes/limpeza.ps1`)

Gerencia a despoluição de disco rígido, remoção de arquivos temporários e limpeza de perfis antigos.

#### Log Integrado
* **Caminho do Log**: `C:\registrolimpezapreventiva.txt`
* **Funções de Log**:
  * `Iniciar-Log($tipo)`: Sobrescreve logs anteriores, registra data de início, usuário ativo (`$env:USERNAME`) e hostname (`$env:COMPUTERNAME`).
  * `Escrever-Resumo($descricao, $quantidade, $mb)`: Registra métricas parciais de remoção.
  * `Finalizar-Log($inicio, $totalArquivos, $totalMB)`: Grava o resumo final consolidado.

#### Helper Auxiliar
* `Medir-Caminho($caminho)`: Varre recursivamente o caminho especificado (`Get-ChildItem -Recurse -Force`), calcula o total de itens, soma o tamanho em bytes e retorna um objeto de tabela hash com `Quantidade`, `Bytes` e `MB`.

#### Funções do Módulo:
1. `Executar-LimpezaRapida` (Privada/Base):
   * Limpa `%TEMP%` do usuário atual.
   * Limpa `C:\Windows\Temp`.
   * Limpa a pasta `AppData\Local\Temp` de todos os usuários cadastrados em `C:\Users` (excluindo pastas do sistema: `Public`, `Default`, etc.).
   * Esvazia recursivamente a Lixeira do sistema (`C:\$Recycle.Bin`), ignorando o arquivo `desktop.ini`.
2. `Limpeza-Rapida` (Pública):
   * Invoca `Executar-LimpezaRapida`, calcula total de megabytes liberados, exibe no terminal e gera registro no log.
3. `Limpeza-Completa` (Pública):
   * Requer confirmação explícita do operador (`S/N`).
   * Executa a `Executar-LimpezaRapida`.
   * Limpa pastas pessoais (`Documents`, `Downloads`, `Pictures`, `Videos`, `Favorites`, `Links`, `Searches`) de todos os usuários locais.
   * **Proteção do Desktop**: Varre a área de trabalho dos usuários removendo arquivos, mas preservando atalhos (`.lnk`, `.url`, `.website`).
   * Limpa os diretórios de cache do Google Chrome e Microsoft Edge.
4. `Limpar-PerfisInativos` (Pública):
   * Requer confirmação explícita.
   * Consulta os perfis de usuário via CIM (`Get-CimInstance Win32_UserProfile`), filtrando perfis que não sejam do sistema (`Special -eq $false`) e não estejam carregados na memória (`Loaded -eq $false`).
   * Filtra perfis cujo `LastUseTime` seja inferior a 10 dias atrás (`(Get-Date).AddDays(-10)`).
   * Remove o perfil do sistema via `Remove-CimInstance -InputObject $perfil`.
5. `Desligar-Maquina`:
   * Executa `shutdown /s /t 5` para encerramento programado.

---

### 📊 3.2. Módulo de Auditoria e Inventário (`funcoes/auditoria.ps1`)

Realiza o levantamento minucioso do parque computacional sem requerer ferramentas ou agentes de terceiros.

#### Coleta de Dados Base (`Coletar-Inventario`)
Utiliza a API CIM (Common Information Model) para obter:
* **Sistema**: Hostname, Domínio AD, Nome da Versão e Build do Windows, Data de Instalação/Formatação.
* **Hardware**: Número de Série (BIOS), Modelo do Processador (CPU), Memória RAM Total (GB), Tamanho Total e Livre do Disco `C:`.
* **Rede**: Endereço IP IPv4 primário e Endereço MAC físico.

#### Formatos de Exportação Disponíveis:
1. `Auditoria-Terminal`: Exibe o inventário formatado diretamente no console PowerShell com cores destacadas.
2. `Auditoria-CSV`: Exporta os dados para o Desktop do usuário no formato `Auditoria_<HOSTNAME>.csv` com codificação UTF-8 e delimitador ponto e vírgula (`;`), ideal para importação no Microsoft Excel.
3. `Auditoria-XML`: Exporta via `Export-Clixml` para `Auditoria_<HOSTNAME>.xml`, ideal para consumo em scripts automatizados de gerência.
4. `Auditoria-TXT`: Gera relatórios em texto simples em `Auditoria_<HOSTNAME>.txt`.

---

### 🛠️ 3.3. Módulo de Manutenção e Diagnóstico (`funcoes/manutencao.ps1`)

Concentra as ferramentas de diagnósticos avançados de rede, reparos do SO e utilitários de gestão de contas e GPO.

#### Funções do Módulo:
1. `Teste-Rede`:
   * **Ping de Internet**: Testa conectividade externa com o servidor DNS público da Google (`8.8.8.8`).
   * **Resolução DNS**: Testa a resolução do domínio `google.com` via `Resolve-DnsName`.
   * **Portais Institucionais**: Envia requisições `HTTP HEAD` (`Invoke-WebRequest`) para validar a acessibilidade e status code dos sistemas:
     * SIA: `https://sia.estacio.br/`
     * SAVA: `https://estudante.estacio.br/`
     * ADP: `https://expert.cloud.brasil.adp.com/expert2/v5/`
   * **Informações de Interface**: Exibe tabela formatada das placas de rede ativas com IPv4.
2. `Sistema-Scan`:
   * Executa a verificação de integridade dos arquivos do sistema: `sfc /scannow`.
   * Executa o reparo da imagem do Windows: `Repair-WindowsImage -Online -RestoreHealth`.
3. `Corrigir-WindowsUpdate`:
   * Interrompe os serviços essenciais: `wuauserv` (Windows Update), `bits` (Background Intelligent Transfer Service) e `cryptsvc` (Cryptographic Services).
   * Limpa as pastas de cache corrompidas `C:\Windows\SoftwareDistribution\Download` e `DataStore`.
   * Reinicia os serviços interrompidos.
4. `Limpar-WindowsUpdate`:
   * Remove com segurança o acúmulo de instaladores de atualizações passadas em `C:\Windows\SoftwareDistribution\Download\*`, calculando o espaço liberado em MB.
5. `Resetar-SenhaUsuario`:
   * Lista os usuários locais cadastrados na máquina via `Get-LocalUser`.
   * Solicita o nome exato da conta e a nova senha através de entrada mascarada (`Read-Host -AsSecureString`).
   * Redefine a credencial utilizando `Set-LocalUser`.
6. `Reiniciar-AdaptadorRede`:
   * Filtra e exibe placas de rede em estado `Up`.
   * Permite que o operador escolha o número do adaptador e executa `Disable-NetAdapter` seguido de `Enable-NetAdapter` (com pausa de 2 segundos).
7. `Verificar-Disco` (`chkdsk`):
   * **Modo 1 (Leitura Rápida)**: Executa `chkdsk C:` sem interrupção do sistema.
   * **Modo 2 (Correção Profunda)**: Passa a flag `echo y | chkdsk C: /f /r` no CMD para agendar a verificação de superfície no próximo reboot.
8. `Atualizar-GPOs`:
   * Força a atualização das Diretivas de Grupo locais e de domínio com `gpupdate /force`.
   * Valida o canal seguro com o Active Directory utilizando `Test-ComputerSecureChannel`.
9. `Instalar-RSAT`:
   * Valida se a máquina pertence a um domínio (`Win32_ComputerSystem.PartOfDomain`).
   * Instala as ferramentas do Active Directory (`Rsat.ActiveDirectory.DS-LDS.Tools`) e Gerenciador de GPO (`Rsat.GroupPolicy.Management.Tools`) via `Add-WindowsCapability`.

---

## 📋 4. Requisitos de Execução e Segurança

| Requisito | Especificação Mínima | Recomendado |
| :--- | :--- | :--- |
| **Sistema Operacional** | Windows 10 Pro / Enterprise (x64) | Windows 10 / 11 Pro / Enterprise |
| **Ambiente de Scripting** | PowerShell 5.1 | PowerShell 5.1 ou PowerShell 7.x |
| **Privilégios** | Administrador Local | Administrador do Domínio / Administrador Local |
| **Rede** | Conexão Local / Ethernet | Acesso aos servidores Active Directory (`CORP`/`ACAD`) |

> ⚠️ **AVISO DE SEGURANÇA**:
> A função `Limpeza-Completa` apaga conteúdos de pastas de perfil de usuário (`Downloads`, `Documents`, etc.) e a função `Limpar-PerfisInativos` remove diretórios inteiros de usuários. **Nunca execute essas funções em computadores de uso estritamente pessoal ou administrativo sem prévio backup dos dados do usuário.**

---

## 💻 5. Diretrizes de Desenvolvimento e Boas Práticas

Ao modificar ou estender a ferramenta `suporTI---Estacio`, siga obrigatoriamente estas regras:

1. **Nomenclatura Padrão PowerShell**:
   * Utilize a convenção `Verbo-Substantivo` em Português para nomear funções (ex: `Testar-Conexao`, `Obter-Dados`).
   * Utilize os verbos aprovados pelo PowerShell (`Get`, `Set`, `Test`, `Clean`, `Remove`, `Start`, `Stop`).
2. **Tratamento Seguro de Erros**:
   * O script principal define `$ErrorActionPreference = "Stop"`.
   * Toda chamada a funções do sistema operacional sujeita a falha (I/O de arquivo, serviços, chamadas de rede) deve estar contida em blocos `try { ... } catch { ... }`.
   * Forneça retornos visuais amigáveis ao operador (`Write-Host` com `-ForegroundColor Cyan/Green/Yellow/Red`).
3. **Modularidade e Escopo**:
   * Não adicione lógica pesada de execução dentro do arquivo `menu.ps1`. O `menu.ps1` deve permanecer estritamente como orquestrador do loop de interface.
   * Novas funcionalidades devem ser adicionadas dentro do módulo correspondente (`limpeza.ps1`, `auditoria.ps1`, `manutencao.ps1`) ou em um novo arquivo `.ps1` criado na pasta `funcoes/`.
4. **Respeito à Codificação de Arquivos**:
   * Salve todos os arquivos de script em codificação **UTF-8 com BOM (or standard UTF-8)** para evitar corrupção de caracteres acentuados ou caracteres de banner ASCII em diferentes builds do Windows.

---

## 🔄 6. Instruções de Retomada dos Trabalhos

Se você é um assistente IA ou um novo desenvolvedor assumindo o projeto, siga estes passos para dar continuidade:

1. **Leitura e Verificação do Estado**:
   * Inspecione o repositório e confirme que os arquivos `Executar.bat`, `menu.ps1`, `funcoes/limpeza.ps1`, `funcoes/auditoria.ps1` e `funcoes/manutencao.ps1` estão intactos.
2. **Ambiente de Teste**:
   * Teste as rotinas em uma Máquina Virtual (VM) Windows 10/11 ou em um ambiente de homologação antes de implantar em laboratórios de produção.
3. **Adicionando Nova Funcionalidade**:
   * crie a função no arquivo apropriado em `funcoes/`.
   * Adicione a validação em `menu.ps1` caso seja um novo módulo.
   * Atualize as opções de menu numérico correspondentes no bloco `switch`.
   * Atualize os arquivos `README.md` e `GEMINI.md` documentando as alterações.
4. **Workflow Git**:
   * Valide as alterações localmente.
   * Execute o ciclo de commit com mensagens claras em português:
     ```bash
     git add .
     git commit -m "feat(modulo): descricao clara da melhoria"
     git push origin main
     ```
