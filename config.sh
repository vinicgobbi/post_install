#!/usr/bin/env bash
# ==========================================
# Configuração compartilhada
# ==========================================

# Detecta o ambiente de desktop atual (kde | gtk). O script roda via sudo,
# que por padrão limpa XDG_CURRENT_DESKTOP (env_reset), então essa variável
# quase nunca chega até aqui — por isso também checamos se o plasmashell está
# instalado no sistema, o que não depende do ambiente herdado do sudo.
# Outros módulos leem $DESKTOP_ENV para pular/adaptar passos específicos de
# GNOME/GTK quando rodando em Plasma.
DESKTOP_ENV="gtk"
if [[ "$XDG_CURRENT_DESKTOP" == *"KDE"* ]] || comando_existe plasmashell; then
    DESKTOP_ENV="kde"
fi

if [[ "$DESKTOP_ENV" == "kde" ]]; then
  # Lista otimizada para o Plasma (com equivalentes em QT + seus apps mantidos)
  FLATPAKS=(
    # Seus apps mantidos por escolha:
    com.spotify.Client io.ente.auth io.github.flattool.Warehouse
    md.obsidian.Obsidian org.libreoffice.LibreOffice
    org.onlyoffice.desktopeditors io.dbeaver.DBeaverCommunity

    # Já são nativos em Qt:
    com.mikrotik.WinBox com.obsproject.Studio org.qbittorrent.qBittorrent
    org.telegram.desktop org.videolan.VLC

    # Equivalentes em Qt:
    org.kde.umbrello       # No lugar de Gaphor
    org.kde.krdc           # No lugar de Remmina

    # Sem Flatpak no Flathub (org.kde.krusader não existe); mantido:
    org.filezillaproject.Filezilla
  )
else
  # Mantém exatamente a sua lista original (GTK / Padrão)
  FLATPAKS=(
    com.getpostman.Postman com.github.tchx84.Flatseal
    com.mattjakeman.ExtensionManager com.mikrotik.WinBox
    com.obsproject.Studio com.spotify.Client dev.vencord.Vesktop
    io.dbeaver.DBeaverCommunity io.ente.auth io.github.flattool.Ignition io.github.flattool.Warehouse
    io.missioncenter.MissionCenter md.obsidian.Obsidian
    org.filezillaproject.Filezilla org.gaphor.Gaphor org.gnome.Boxes
    org.libreoffice.LibreOffice org.onlyoffice.desktopeditors org.qbittorrent.qBittorrent
    org.remmina.Remmina org.telegram.desktop org.videolan.VLC me.iepure.devtoolbox
  )
fi

FLATPAKS_JOGOS=(
  com.heroicgameslauncher.hgl com.valvesoftware.Steam
  com.vysp3r.ProtonPlus org.prismlauncher.PrismLauncher
)

# ==========================================
# Migração para Snap (só no Ubuntu, $ID == "ubuntu")
# ==========================================
# Apps que, especificamente no Ubuntu, instalamos via Snap em vez de
# Flatpak/apt/deb. Fora do Ubuntu (Debian, Mint, etc.) essa lista é ignorada
# e os módulos seguem instalando via Flatpak/apt normalmente.
#
# Formato de cada entrada, separado por "|":
#   título | tipo_origem | valor_origem | pacote_snap | classic
#   - tipo_origem:  "flatpak" ou "apt" (como o app é instalado hoje)
#   - valor_origem: id do Flatpak, ou nome do pacote apt/dpkg
#   - classic:      "classic" se o snap precisa de --classic, vazio se não
#
# Usada por lib/utils.sh (filtrar_flatpaks_migrados_snap), pelo módulo
# modules/19_snap_apps.sh e pelo script migrar_para_snap.sh.
SNAP_MIGRACAO=(
    "Obsidian|flatpak|md.obsidian.Obsidian|obsidian|classic"
    "Postman|flatpak|com.getpostman.Postman|postman|classic"
    "DBeaver CE|flatpak|io.dbeaver.DBeaverCommunity|dbeaver-ce|"
    "LibreOffice|flatpak|org.libreoffice.LibreOffice|libreoffice|"
    "OnlyOffice|flatpak|org.onlyoffice.desktopeditors|onlyoffice-desktopeditors|"
    "VLC|flatpak|org.videolan.VLC|vlc|"
    "Remmina|flatpak|org.remmina.Remmina|remmina|"
    "Steam|flatpak|com.valvesoftware.Steam|steam|"
    "Heroic Games Launcher|flatpak|com.heroicgameslauncher.hgl|heroic|classic"
    "Visual Studio Code|apt|code|code|classic"
    "Bitwarden|apt|bitwarden|bitwarden|"
)
