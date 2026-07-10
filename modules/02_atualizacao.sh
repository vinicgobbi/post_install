#!/usr/bin/env bash

atualizar_sistema() {
    info "Atualizando pacotes do sistema..."
    if [[ "$PKG_MGR" == "dnf" ]]; then
        dnf upgrade --refresh -y
    else
        apt-get update && apt-get upgrade -y
    fi
    sucesso "Sistema atualizado."
}

registrar_modulo "atualizacao" "Atualizar sistema" \
    "Roda o upgrade completo de pacotes do sistema" \
    "atualizar_sistema"
