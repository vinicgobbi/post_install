#!/usr/bin/env bash

limpeza_final() {
    info "Limpando o sistema..."
    if [[ "$PKG_MGR" == "dnf" ]]; then
        dnf autoremove -y
        dnf clean all
    elif [[ "$PKG_MGR" == "pacman" ]]; then
        local orfaos
        orfaos=$(pacman -Qtdq 2>/dev/null || true)
        [[ -n "$orfaos" ]] && pacman -Rns --noconfirm $orfaos
        pacman -Sc --noconfirm

        if [[ -f /etc/sudoers.d/99-post-install-aur ]]; then
            rm -f /etc/sudoers.d/99-post-install-aur
            info "Regra temporária de sudo sem senha para o pacman (liberada para o yay) removida."
        fi
    else
        apt autoremove -y
        apt clean
    fi
    rm -rf /tmp/* 2>/dev/null || true
    sucesso "Instalação finalizada com sucesso!"
    info "Recomenda-se reiniciar a máquina para aplicar as mudanças de grupo e kernel."
}

registrar_modulo "limpeza" "Limpeza final" \
    "Remove pacotes órfãos e limpa o cache do gerenciador de pacotes" \
    "limpeza_final"
