# POST — Script de pós-instalação

Script modular para configurar uma workstation Linux recém-instalada: mirrors,
atualização do sistema, Docker, VSCode, PHP + SQL Server, Flatpaks (incluindo
jogos — Steam, Heroic, ProtonPlus, PrismLauncher), Tailscale + Trayscale,
Chrome, Bitwarden, temas/ícones GNOME, o ambiente do usuário (zsh, Oh My Zsh,
fnm/Node, dotfiles pessoais), Rust (rustup, eza, topgrade), Claude Code,
importação de perfis OpenVPN e a extensão do VSCode para o Nautilus.

## Sistemas suportados

| Família  | Distribuições                          | Gerenciador |
|----------|-----------------------------------------|-------------|
| Fedora   | Fedora Linux                            | `dnf`       |
| RHEL     | AlmaLinux e derivados (`ID_LIKE=rhel/centos`) | `dnf` |
| Debian   | Ubuntu (bionic, focal, jammy, noble)     | `apt`       |
| Debian   | Debian (bullseye, bookworm)              | `apt`       |

Se a distribuição/versão não estiver nessa lista, o script para com uma
mensagem clara em vez de continuar em um estado incerto.

## Como usar

```bash
sudo ./setup.sh
```

O script precisa rodar como root. O fluxo é:

1. Detecta o sistema operacional e mostra o que foi identificado.
2. Pergunta para qual usuário do sistema o ambiente deve ser configurado
   (sem sugerir nome, precisa digitar; valida que o usuário existe).
3. Abre um **menu interativo de checklist** com todos os módulos, já marcados
   por padrão:
   - `↑` / `↓` — mover o cursor
   - `espaço` — marcar/desmarcar o módulo atual
   - `a` — marcar/desmarcar todos de uma vez
   - `enter` — confirmar a seleção
4. Mostra um resumo dos módulos escolhidos e pede confirmação (`s/N`) antes
   de começar.
5. Executa cada módulo selecionado, na ordem correta de dependência, exibindo
   `[passo/total] nome do módulo`.
6. No final, mostra um resumo com os módulos executados e o tempo total.

Se o script for executado de forma não interativa (stdin não é um terminal —
por exemplo, `curl | bash` ou dentro de outro script), o menu é pulado
automaticamente e **todos** os módulos rodam, com um aviso.

Pressionar `Ctrl+C` a qualquer momento cancela com uma mensagem amigável em
vez de um abort cru do bash.

## Log em arquivo

Tanto o `setup.sh` quanto o `migrar_para_snap.sh` gravam dois arquivos por
execução em `logs/` (criada na raiz do repo, ignorada pelo git):

- `<script>_<timestamp>.log` — só as mensagens `info`/`aviso`/`erro`/`sucesso`/
  `passo`, com hora e nível, sem código de cor. Bom para uma leitura rápida
  do que rodou.
- `<script>_<timestamp>.raw.log` — transcrição bruta e completa de tudo que
  passa pelo terminal durante a fase de execução dos módulos, incluindo a
  saída crua de `apt`/`dnf`/`curl`/`flatpak`/`snap`. Bom para investigar o
  motivo de uma falha.

O log bruto só começa a ser gravado depois do menu interativo (na fase de
execução), de propósito — redirecionar a saída do processo antes disso
quebraria a detecção de terminal usada pelo menu de checklist.

## Estrutura do projeto

```
setup.sh                    # ponto de entrada — orquestra tudo
config.sh                   # constantes compartilhadas (lista de Flatpaks)
lib/
  ui.sh                     # cores, mensagens, menu interativo, prompts, resumo final
  os_detect.sh               # detecção de SO/versão/gerenciador de pacotes
  utils.sh                  # helpers (comando_existe, executar_como_usuario, download_com_retry, registro de módulos)
modules/
  01_mirrors.sh             # otimização de mirrors do gerenciador de pacotes
  02_atualizacao.sh         # upgrade completo do sistema
  03_repositorios.sh        # repositórios Docker, VSCode e Microsoft SQL
  04_pacotes_base.sh        # Docker, VSCode, PHP, Zsh, ferramentas SQL Server
  05_solaar.sh              # regras UDEV para o receptor Logitech Unifying
  06_remover_libreoffice.sh # remove o LibreOffice nativo da distro
  07_flatpaks.sh            # instala a lista de apps Flatpak
  08_flatpaks_jogos.sh      # Steam, Heroic, ProtonPlus e PrismLauncher
  09_tailscale.sh           # Tailscale + Trayscale, define o usuário como operator
  10_php_extensoes.sh       # extensões PHP sqlsrv/pdo_sqlsrv via PECL
  11_chrome_gcm.sh          # Google Chrome + Git Credential Manager
  12_bitwarden.sh           # Bitwarden desktop nativo
  13_temas_icones.sh        # tema adw-gtk3 e ícones Yaru
  14_ambiente_usuario.sh    # fnm/Node, clona Dotfiles e roda o bootstrap.sh dele, gsettings
  15_rust_tools.sh          # rustup + compilação de eza e topgrade via cargo
  16_claude_code.sh         # instala o Claude Code (CLI da Anthropic)
  17_snap_apps.sh           # instala apps via Snap (só Ubuntu, ver seção abaixo)
  18_vscode_nautilus.sh     # extensão "Abrir com o VSCode" no menu do Nautilus
  19_ovpn.sh                # instala plugin OpenVPN e importa perfis de ./OVPN
  20_virt_manager.sh        # QEMU/KVM, libvirt e virt-manager (módulo à parte — desmarque no menu se não quiser)
  21_limpeza.sh             # autoremove/clean do gerenciador de pacotes
migrar_para_snap.sh          # script à parte: migra apps já instalados para Snap
```

Cada arquivo em `modules/` define uma função (mesmo nome de antes, ex.:
`otimizar_mirrors`) e termina chamando `registrar_modulo id titulo descricao
nome_da_funcao`, que é como o módulo "se anuncia" para aparecer no menu do
`setup.sh` — não é preciso editar o orquestrador para adicionar/remover
etapas, só criar ou apagar o arquivo em `modules/`.

## Adicionando ou editando um módulo

1. Crie `modules/NN_nome.sh` (o prefixo numérico define a ordem de execução).
2. Defina uma função com a lógica do módulo, usando `info`/`sucesso`/`aviso`/`erro`
   de `lib/ui.sh` para as mensagens.
3. No final do arquivo, registre o módulo:
   ```bash
   registrar_modulo "id_curto" "Título no menu" "Descrição de uma linha" "nome_da_funcao"
   ```
4. Pronto — `setup.sh` carrega todos os arquivos em `modules/*.sh`
   automaticamente (em ordem alfabética/numérica) e o novo módulo aparece
   no menu.

## Detecção de sistema (`lib/os_detect.sh`)

`detectar_sistema` define as seguintes variáveis globais, usadas pelos
módulos:

- `OS_FAMILY` — `fedora`, `rhel` ou `debian`
- `PKG_MGR` — `dnf` ou `apt`
- `RHEL_VERSION` — só para família `rhel` (ex.: `9`)
- `ARCH`, `BASE_CODENAME`, `DISTRO_VERSION` — só para família `debian`
- `DOCKER_DISTRO` — `ubuntu` ou `debian`, usado para montar as URLs corretas
  do repositório do Docker
- `MS_REPO_SUPPORTED` — `1` se a Microsoft publica repositório oficial
  (msodbcsql/mssql-tools) para essa combinação de distro+versão; se for `0`,
  o módulo `03_repositorios` e `04_pacotes_base` pulam essa parte com um
  aviso em vez de abortar o script inteiro.

## Apps via Snap no Ubuntu (`modules/17_snap_apps.sh`)

No Ubuntu (`$ID == "ubuntu"`, não em Mint/outros derivados), os seguintes
apps são instalados via Snap em vez de Flatpak/apt, porque o snapd já vem
pronto de fábrica no Ubuntu: **Obsidian, Postman, DBeaver CE, LibreOffice,
OnlyOffice, VLC, Steam, VSCode e Bitwarden**. Remmina fica de fora por
escolha — continua via Flatpak em todas as distros. A lista com o
mapeamento (id do Flatpak/pacote apt → pacote Snap, e se precisa de
`--classic`) fica em `SNAP_MIGRACAO`, em `config.sh` — os confinamentos
(`classic`/`strict`) foram conferidos na API oficial da Snap Store
(`api.snapcraft.io`), não chutados.

Heroic Games Launcher **não migrou**: não existe snap oficial dele (nem
`heroic`, nem variações do nome) na Snap Store, então continua instalado via
Flatpak (`com.heroicgameslauncher.hgl`) em todas as distros, inclusive
Ubuntu.

Para isso, os módulos `07_flatpaks`, `08_flatpaks_jogos`, `12_bitwarden`,
`04_pacotes_base` e `03_repositorios` pulam esses apps especificamente no
Ubuntu (usando `filtrar_flatpaks_migrados_snap` de `lib/utils.sh`), e
`17_snap_apps` instala a versão Snap de cada um. Em qualquer outra distro
(Debian, Mint, Fedora, RHEL) nada muda — todos continuam instalados como
antes (Flatpak/apt).

Se quiser adicionar/remover apps dessa migração, edite apenas o array
`SNAP_MIGRACAO` em `config.sh`.

## Migrando um sistema já instalado para Snap (`migrar_para_snap.sh`)

Script separado do `setup.sh`, pensado para uma máquina que **já tem** essas
apps instaladas em Flatpak/apt e você quer trocar para Snap sem reinstalar
tudo do zero:

```bash
sudo ./migrar_para_snap.sh
```

O fluxo:

1. Confirma que o sistema é Ubuntu (aborta em qualquer outra distro).
2. Abre o mesmo menu de checklist do `setup.sh`, listando os apps de
   `SNAP_MIGRACAO` — **você escolhe quais migrar, não precisa ser todos**.
3. Para cada app escolhido: desinstala a versão atual (Flatpak ou apt/deb,
   só se estiver de fato instalada) e instala a versão em Snap no lugar.
4. Não apaga dados de apps Flatpak (`~/.var/app/<id>/`) — eles só não são
   aproveitados automaticamente pelo Snap, então configurações/logins de
   apps migrados podem precisar ser refeitos.

## Importação de perfis OpenVPN (`modules/19_ovpn.sh`)

Antes de rodar o setup, copie os arquivos `.ovpn` para a pasta `OVPN/` do
próprio projeto (veja `OVPN/README.md`). O módulo:

1. Garante que o plugin OpenVPN do NetworkManager esteja instalado (instala
   se estiver faltando).
2. Importa cada `.ovpn` de `OVPN/*.ovpn` como uma conexão do
   NetworkManager (reimportando do zero em reexecuções, para não duplicar).
3. Se o arquivo declarar `dhcp-option DNS` e/ou `dhcp-option DOMAIN`
   (domínio de busca), aplica esses valores manualmente na conexão via
   `nmcli` — a importação automática nem sempre preenche isso.

Se `OVPN/` estiver vazia, o módulo é pulado com um aviso. Os arquivos `.ovpn`
não são versionados (só o README dentro da pasta) — veja `.gitignore`.

## Requisitos

- Bash (usa arrays, `local -n` nameref, `[[ ]]`) — testado com Bash 5.2.
- Acesso root (`sudo`).
- Terminal interativo real para usar o menu de setas (se rodar via pipe/CI,
  o script detecta e roda tudo automaticamente).

## Limitações conhecidas

- O menu de checklist é implementado em bash puro (sem `whiptail`/`dialog`)
  para não depender de pacotes que podem não estar instalados numa máquina
  recém-formatada.
- Distribuições/versões fora da tabela de `lib/os_detect.sh` não são
  suportadas — o script para com uma mensagem explicando o motivo em vez de
  tentar adivinhar.
