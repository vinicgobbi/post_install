#!/usr/bin/env bash

instalar_pacotes_base() {
    info "Instalando pacotes base e utilitários..."
    if [[ "$PKG_MGR" == "dnf" ]]; then
        ACCEPT_EULA=Y dnf install -y flatpak code zsh git curl jq docker-ce docker-ce-cli \
            containerd.io docker-buildx-plugin docker-compose-plugin php composer \
            php-devel php-xml php-pear msodbcsql18 mssql-tools18 unixODBC-devel
    else
        local EXTRAS="code"
        [[ "$ID" == "ubuntu" ]] && EXTRAS="code gnome-software gnome-software-plugin-flatpak"

        apt-get install -y flatpak zsh git curl jq docker-ce docker-ce-cli \
            containerd.io docker-buildx-plugin docker-compose-plugin php composer \
            php-dev php-xml php-pear $EXTRAS

        if [[ "$MS_REPO_SUPPORTED" == "1" ]]; then
            ACCEPT_EULA=Y apt-get install -y msodbcsql18 mssql-tools18 unixodbc-dev
        else
            aviso "Pulando msodbcsql18/mssql-tools18 (sem repositório oficial da Microsoft para esta distro/versão)."
        fi
    fi
    echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' > /etc/profile.d/mssql-tools.sh
    sucesso "Pacotes e MS SQL instalados."
}

registrar_modulo "pacotes_base" "Instalar pacotes base" \
    "Docker, VSCode, PHP, Zsh e ferramentas de SQL Server" \
    "instalar_pacotes_base"
