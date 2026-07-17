#!/usr/bin/env bash

instalar_solaar() {
    info "Instalando Solaar..."

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
    instalar_solaar

    info "Configurando regras UDEV para o Solaar..."

    getent group plugdev >/dev/null || groupadd plugdev
    usermod -aG plugdev "$USER_NAME"

    curl -sL https://raw.githubusercontent.com/pwr-Solaar/Solaar/master/rules.d-uinput/42-logitech-unify-permissions.rules -o /etc/udev/rules.d/42-logitech-unify-permissions.rules

    udevadm control --reload-rules
    udevadm trigger --subsystem-match=usb
    udevadm trigger --subsystem-match=hidraw

    sucesso "Regras UDEV do Solaar configuradas."
}

registrar_modulo "solaar" "Instalar e configurar Solaar" \
    "Instala o Solaar (nativo, com fallback para Flatpak) e configura regras UDEV para o receptor Logitech Unifying" \
    "configurar_solaar"
