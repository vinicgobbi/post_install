#!/usr/bin/env bash

remover_libreoffice_nativo() {
    info "Removendo LibreOffice pré-instalado..."
    if [[ "$PKG_MGR" == "dnf" ]]; then
        dnf remove -y libreoffice*
    elif [[ "$PKG_MGR" == "pacman" ]]; then
        local pacotes
        pacotes=$(pacman -Qq | grep '^libreoffice' || true)
        if [[ -n "$pacotes" ]]; then
            pacman -Rns --noconfirm $pacotes
        else
            info "Nenhum pacote libreoffice* instalado nativamente."
        fi
    else
        apt remove --purge -y libreoffice*
    fi
    sucesso "LibreOffice nativo removido."
}

registrar_modulo "remover_libreoffice" "Remover LibreOffice nativo" \
    "Remove o LibreOffice do sistema (será substituído pela versão Flatpak)" \
    "remover_libreoffice_nativo"
