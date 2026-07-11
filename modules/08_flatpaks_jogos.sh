#!/usr/bin/env bash

instalar_flatpaks_jogos() {
    info "Instalando Flatpaks de jogos..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    flatpak install -y flathub "${FLATPAKS_JOGOS[@]}"
    sucesso "Flatpaks de jogos instalados."
}

registrar_modulo "flatpaks_jogos" "Instalar Flatpaks de jogos" \
    "Steam, Heroic Games Launcher, ProtonPlus e PrismLauncher" \
    "instalar_flatpaks_jogos"
