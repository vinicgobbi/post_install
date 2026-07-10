#!/usr/bin/env bash

configurar_solaar() {
    info "Configurando regras UDEV para o Solaar..."

    getent group plugdev >/dev/null || groupadd plugdev
    usermod -aG plugdev "$USER_NAME"

    curl -sL https://raw.githubusercontent.com/pwr-Solaar/Solaar/master/rules.d-uinput/42-logitech-unify-permissions.rules -o /etc/udev/rules.d/42-logitech-unify-permissions.rules

    udevadm control --reload-rules
    udevadm trigger --subsystem-match=usb
    udevadm trigger --subsystem-match=hidraw

    sucesso "Regras UDEV do Solaar configuradas."
}

registrar_modulo "solaar" "Configurar Solaar" \
    "Regras UDEV e permissões para o receptor Logitech Unifying" \
    "configurar_solaar"
