#!/usr/bin/env bash

configurar_temas_e_icones() {
    info "Configurando temas e ícones globais em /usr/share..."
    mkdir -p /usr/share/themes /usr/share/icons

    # --- Tema adw-gtk3 ---
    if [[ "$ID" != "ubuntu" ]]; then
        info "Verificando adw-gtk3 nos repositórios..."
        local ADW_PKG=""
        if [[ "$PKG_MGR" == "dnf" ]]; then
            dnf list available adw-gtk3-theme &>/dev/null && ADW_PKG="adw-gtk3-theme"
        else
            apt-cache show adw-gtk3 &>/dev/null && ADW_PKG="adw-gtk3"
        fi

        if [[ -n "$ADW_PKG" ]]; then
            info "Instalando adw-gtk3 via gerenciador de pacotes nativo..."
            if [[ "$PKG_MGR" == "dnf" ]]; then dnf install -y "$ADW_PKG"; else apt-get install -y "$ADW_PKG"; fi
        else
            info "adw-gtk3 ausente dos repositórios. Baixando tarball oficial do GitHub..."
            local ADW_URL
            ADW_URL=$(curl -sL https://api.github.com/repos/lassekongo83/adw-gtk3/releases/latest | jq -r '.assets[] | select(.name | endswith(".tar.xz")) | .browser_download_url' | head -n 1)
            if [[ -n "$ADW_URL" ]]; then
                curl -sSL "$ADW_URL" | tar -xJ -C /usr/share/themes/
            fi
        fi
    fi

    # --- Ícones Yaru ---
    info "Verificando ícones Yaru nos repositórios..."
    local YARU_PKG=""
    if [[ "$PKG_MGR" == "dnf" ]]; then
        dnf list available yaru-icon-theme &>/dev/null && YARU_PKG="yaru-icon-theme"
    else
        apt-cache show yaru-theme-icon &>/dev/null && YARU_PKG="yaru-theme-icon"
    fi

    if [[ -n "$YARU_PKG" ]]; then
        info "Instalando ícones Yaru via gerenciador de pacotes nativo..."
        if [[ "$PKG_MGR" == "dnf" ]]; then dnf install -y "$YARU_PKG"; else apt-get install -y "$YARU_PKG"; fi
    else
        info "Ícones Yaru ausentes dos repositórios. Baixando do repositório oficial do Ubuntu..."
        mkdir -p /tmp/yaru-icons
        curl -sSL https://github.com/ubuntu/yaru/archive/refs/heads/master.tar.gz | tar -xz -C /tmp/yaru-icons
        cp -r /tmp/yaru-icons/yaru-master/icons/* /usr/share/icons/ 2>/dev/null || true
        rm -rf /tmp/yaru-icons
    fi
    sucesso "Temas e ícones implantados no sistema."
}

registrar_modulo "temas_icones" "Temas e ícones" \
    "Instala o tema adw-gtk3 e os ícones Yaru" \
    "configurar_temas_e_icones"
