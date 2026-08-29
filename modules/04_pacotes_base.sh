#!/usr/bin/env bash

instalar_pacotes_base() {
    info "Instalando pacotes base e utilitários..."
    if [[ "$PKG_MGR" == "pacman" ]]; then
        # Docker, PHP/composer e unixODBC são oficiais (repo extra/core); code,
        # msodbcsql e mssql-tools só existem na AUR (o pacman resolve pelo
        # Chaotic-AUR quando disponível, sem compilar — ver módulo "repositorios").
        pacman -S --needed --noconfirm flatpak zsh git curl jq xdg-user-dirs \
            docker docker-compose docker-buildx php composer unixodbc bat

        instalar_pacotes_aur visual-studio-code-bin msodbcsql mssql-tools
    elif [[ "$PKG_MGR" == "dnf" ]]; then
        ACCEPT_EULA=Y dnf install -y flatpak code zsh git curl jq \
            docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin php composer \
            php-devel php-xml php-pear msodbcsql18 mssql-tools18 unixODBC-devel bat
    else
        local EXTRAS="code"
        # gnome-software só faz sentido em Ubuntu com GNOME; em Kubuntu (mesmo
        # $ID) o Discover já cobre Flatpak/Snap, então evitamos puxar o GNOME Software.
        [[ "$ID" == "ubuntu" && "$DESKTOP_ENV" != "kde" ]] && EXTRAS="code gnome-software gnome-software-plugin-flatpak gnome-software-plugin-snap"

        apt install -y flatpak zsh git curl jq \
            docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin php composer \
            php-dev php-xml php-pear bat $EXTRAS

        if [[ "$MS_REPO_SUPPORTED" == "1" ]]; then
            ACCEPT_EULA=Y apt install -y msodbcsql18 mssql-tools18 unixodbc-dev
        else
            aviso "Pulando msodbcsql18/mssql-tools18 (sem repositório oficial da Microsoft para esta distro/versão)."
        fi
    fi

    # Em algumas distros (Debian/Ubuntu) o pacote "bat" instala o binário como
    # "batcat" por conflito de nome; cria um link para "bat" funcionar igual em todo lugar.
    if comando_existe batcat && ! comando_existe bat; then
        ln -sf "$(command -v batcat)" /usr/local/bin/bat
    fi

    # Debian/Fedora instalam em /opt/mssql-tools18; o pacote da AUR usada no
    # Arch instala em /opt/mssql-tools (sem versão) — inclui os dois no PATH,
    # inofensivo o que não existir na distro atual.
    echo 'export PATH="$PATH:/opt/mssql-tools18/bin:/opt/mssql-tools/bin"' > /etc/profile.d/mssql-tools.sh
    sucesso "Pacotes e MS SQL instalados."
}

registrar_modulo "pacotes_base" "Instalar pacotes base" \
    "Docker, VSCode, PHP, Zsh e ferramentas de SQL Server" \
    "instalar_pacotes_base" "repositorios"
