#!/usr/bin/env bash

instalar_apps_snap() {
    if [[ "$ID" != "ubuntu" ]]; then
        aviso "Módulo específico do Ubuntu; pulando (sistema atual: $PRETTY_NAME)."
        return
    fi

    info "Instalando apps via Snap..."
    comando_existe snap || apt install -y snapd

    local entrada titulo snap_nome classic modulo_origem flags
    for entrada in "${SNAP_MIGRACAO[@]}"; do
        IFS='|' read -r titulo _ _ snap_nome classic modulo_origem <<< "$entrada"

        if ! modulo_selecionado "$modulo_origem"; then
            aviso "  Pulando $titulo via Snap: módulo '$modulo_origem' não foi selecionado."
            continue
        fi

        flags=()
        [[ "$classic" == "classic" ]] && flags=(--classic)
        info "  Snap: $titulo ($snap_nome)"
        snap install "$snap_nome" "${flags[@]}"
    done

    sucesso "Apps via Snap instalados."
}

registrar_modulo "snap_apps" "Instalar apps via Snap (Ubuntu)" \
    "Obsidian, Postman, DBeaver, LibreOffice, OnlyOffice, VLC, Steam, VSCode e Bitwarden via Snap. Só roda no Ubuntu." \
    "instalar_apps_snap"
