#!/usr/bin/env bash

instalar_bitwarden_nativo() {
    if [[ "$ID" == "ubuntu" ]]; then
        aviso "No Ubuntu, o Bitwarden é instalado via Snap (módulo 'Instalar apps via Snap'); pulando o .deb."
        return
    fi

    info "Instalando Bitwarden nativo (integração com navegador)..."
    if [[ "$PKG_MGR" == "dnf" ]]; then
        curl -sSL -o /tmp/bitwarden.rpm "https://vault.bitwarden.com/download/?app=desktop&platform=linux&variant=rpm"
        dnf install -y /tmp/bitwarden.rpm
    else
        curl -sSL -o /tmp/bitwarden.deb "https://vault.bitwarden.com/download/?app=desktop&platform=linux&variant=deb"
        apt install -y /tmp/bitwarden.deb
    fi
    sucesso "Bitwarden instalado nativamente."
}

registrar_modulo "bitwarden" "Instalar Bitwarden nativo" \
    "Instala o Bitwarden desktop (necessário para integração nativa com o navegador)" \
    "instalar_bitwarden_nativo"
