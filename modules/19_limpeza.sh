#!/usr/bin/env bash

limpeza_final() {
    info "Limpando o sistema..."
    if [[ "$PKG_MGR" == "dnf" ]]; then
        dnf autoremove -y
        dnf clean all
    else
        apt-get autoremove -y
        apt-get clean
    fi
    rm -rf /tmp/* 2>/dev/null || true
    sucesso "Instalação finalizada com sucesso!"
    info "Recomenda-se reiniciar a máquina para aplicar as mudanças de grupo e kernel."
}

registrar_modulo "limpeza" "Limpeza final" \
    "Remove pacotes órfãos e limpa o cache do gerenciador de pacotes" \
    "limpeza_final"
