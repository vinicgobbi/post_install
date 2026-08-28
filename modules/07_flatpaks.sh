#!/usr/bin/env bash

instalar_flatpaks() {
    info "Configurando Flatpak e instalando apps..."

    local apps=("${FLATPAKS[@]}")

    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    if [[ "${#apps[@]}" -gt 0 ]]; then
        flatpak install -y flathub "${apps[@]}"
    fi
    sucesso "Aplicativos Flatpak instalados."
}

registrar_modulo "flatpaks" "Instalar Flatpaks" \
    "Instala a lista de aplicativos Flatpak (Postman, Spotify, Obsidian, etc.)" \
    "instalar_flatpaks"
