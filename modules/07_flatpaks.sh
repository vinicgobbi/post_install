#!/usr/bin/env bash

instalar_flatpaks() {
    info "Configurando Flatpak e instalando apps..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    flatpak install -y flathub "${FLATPAKS[@]}"
    sucesso "Aplicativos Flatpak instalados."
}

registrar_modulo "flatpaks" "Instalar Flatpaks" \
    "Instala a lista de aplicativos Flatpak (Postman, Spotify, Obsidian, etc.)" \
    "instalar_flatpaks"
