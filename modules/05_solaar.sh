#!/usr/bin/env bash

instalar_solaar() {
    local via_ppa="$1"
    info "Instalando Solaar..."

    # Em Ubuntu (e derivados), a PPA solaar-unifying/stable já traz o Solaar
    # sempre atualizado. As regras UDEV são baixadas à parte em configurar_solaar,
    # independente da origem da instalação.
    if [[ "$via_ppa" == "1" ]]; then
        info "Sistema baseado em Ubuntu: usando a PPA solaar-unifying/stable."
        comando_existe add-apt-repository || apt-get install -y software-properties-common
        add-apt-repository -y ppa:solaar-unifying/stable
        apt-get update
        apt-get install -y solaar
        sucesso "Solaar instalado via PPA solaar-unifying/stable."
        return
    fi

    local pacote_disponivel=0
    if [[ "$PKG_MGR" == "dnf" ]]; then
        dnf info solaar &>/dev/null && pacote_disponivel=1
    else
        apt-cache show solaar &>/dev/null && pacote_disponivel=1
    fi

    if [[ "$pacote_disponivel" == "1" ]]; then
        "$PKG_MGR" install -y solaar
        sucesso "Solaar instalado via pacote nativo ($PKG_MGR)."
    else
        aviso "Pacote nativo do Solaar não encontrado; instalando via Flatpak."
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        flatpak install -y flathub io.github.pwr_solaar.solaar
        sucesso "Solaar instalado via Flatpak."
    fi
}

configurar_solaar() {
    local via_ppa=0
    [[ "$PKG_MGR" == "apt-get" && "$DOCKER_DISTRO" == "ubuntu" ]] && via_ppa=1

    instalar_solaar "$via_ppa"

    getent group plugdev >/dev/null || groupadd plugdev
    usermod -aG plugdev "$USER_NAME"

    info "Configurando regras UDEV para o Solaar..."
    curl -sL https://raw.githubusercontent.com/pwr-Solaar/Solaar/master/rules.d-uinput/42-logitech-unify-permissions.rules -o /etc/udev/rules.d/42-logitech-unify-permissions.rules

    udevadm control --reload-rules
    udevadm trigger --subsystem-match=usb
    udevadm trigger --subsystem-match=hidraw

    sucesso "Regras UDEV do Solaar configuradas."
}

registrar_modulo "solaar" "Instalar e configurar Solaar" \
    "Instala o Solaar (PPA no Ubuntu, nativo nas demais distros, com fallback para Flatpak) e as regras UDEV do receptor Logitech Unifying" \
    "configurar_solaar"
