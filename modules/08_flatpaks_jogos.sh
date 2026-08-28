#!/usr/bin/env bash

instalar_flatpaks_jogos() {
    info "Instalando Flatpaks de jogos..."

    local apps=("${FLATPAKS_JOGOS[@]}")

    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    if [[ "${#apps[@]}" -gt 0 ]]; then
        flatpak install -y flathub "${apps[@]}"
    fi
    sucesso "Flatpaks de jogos instalados."
}

registrar_modulo "flatpaks_jogos" "Instalar Flatpaks de jogos" \
    "Steam, Heroic Games Launcher, ProtonPlus e PrismLauncher" \
    "instalar_flatpaks_jogos"
