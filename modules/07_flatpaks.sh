#!/usr/bin/env bash

instalar_flatpaks() {
    info "Configurando Flatpak e instalando apps..."

    local apps=("${FLATPAKS[@]}")
    filtrar_flatpaks_migrados_snap apps
    if [[ "$ID" == "ubuntu" ]]; then
        aviso "No Ubuntu, alguns apps desta lista são instalados via Snap (módulo 'Instalar apps via Snap'), não aqui."
    fi

    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    if [[ "${#apps[@]}" -gt 0 ]]; then
        flatpak install -y flathub "${apps[@]}"
    fi
    sucesso "Aplicativos Flatpak instalados."
}

registrar_modulo "flatpaks" "Instalar Flatpaks" \
    "Instala a lista de aplicativos Flatpak (Postman, Spotify, Obsidian, etc.)" \
    "instalar_flatpaks"
