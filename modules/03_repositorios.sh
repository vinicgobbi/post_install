#!/usr/bin/env bash

# Chave GPG oficial do Chaotic-AUR (aur.chaotic.cx) — repo binário que serve
# pacotes pré-compilados do AUR (yay incluso), evitando compilar tudo na mão.
CHAOTIC_AUR_KEY="3056513887B78AEB"
SUDOERS_AUR_FILE="/etc/sudoers.d/99-post-install-aur"

# Habilita o repositório Chaotic-AUR seguindo o processo oficial
# (https://aur.chaotic.cx/): importa a chave, instala keyring+mirrorlist via
# pacman -U e inclui o mirrorlist no pacman.conf. Idempotente.
configurar_chaotic_aur() {
    if grep -q '^\[chaotic-aur\]' /etc/pacman.conf 2>/dev/null; then
        info "Chaotic-AUR já configurado."
        return
    fi

    info "Configurando o repositório binário Chaotic-AUR..."
    pacman-key --recv-key "$CHAOTIC_AUR_KEY" --keyserver keyserver.ubuntu.com
    pacman-key --lsign-key "$CHAOTIC_AUR_KEY"
    pacman -U --noconfirm \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

    cat <<'EOF' >> /etc/pacman.conf

[chaotic-aur]
Include = /etc/pacman.d/chaotic-mirrorlist
EOF

    pacman -Sy
    sucesso "Chaotic-AUR configurado."
}

# O yay (e, por baixo, o makepkg) recusa rodar como root, mas o setup.sh
# inteiro roda via sudo. Sem essa liberação, todo módulo que precisa
# instalar algo da AUR pararia pedindo senha no meio da execução
# automática. Regra bem restrita (só o binário do pacman, não ALL) e
# temporária: removida em "Limpeza final" (modules/21_limpeza.sh).
permitir_sudo_pacman_temporario() {
    [[ -f "$SUDOERS_AUR_FILE" ]] && return

    info "Liberando sudo sem senha para o pacman (usuário $USER_NAME) — necessário para o yay instalar pacotes da AUR sem interação; revertido ao final em 'Limpeza final'."
    echo "$USER_NAME ALL=(ALL) NOPASSWD: /usr/bin/pacman" > "$SUDOERS_AUR_FILE"
    chmod 0440 "$SUDOERS_AUR_FILE"
    visudo -cf "$SUDOERS_AUR_FILE" || { rm -f "$SUDOERS_AUR_FILE"; erro "Falha ao validar a regra temporária de sudo para o pacman."; }
}

# Instala o yay: tenta primeiro como binário pronto do Chaotic-AUR (rápido,
# sem compilar); se não estiver disponível, compila da AUR como o usuário
# alvo (makepkg não roda como root).
instalar_yay() {
    comando_existe yay && return

    if pacman -S --needed --noconfirm yay &>/dev/null; then
        sucesso "yay instalado via Chaotic-AUR."
        return
    fi

    info "yay não encontrado como binário no Chaotic-AUR; compilando da AUR..."
    executar_como_usuario "
  rm -rf /tmp/yay-build
  git clone https://aur.archlinux.org/yay.git /tmp/yay-build
  cd /tmp/yay-build
  makepkg -si --noconfirm
"
    rm -rf /tmp/yay-build
    sucesso "yay compilado e instalado."
}

configurar_repositorios() {
    info "Configurando repositórios (Docker, Microsoft)..."

    if [[ "$PKG_MGR" == "pacman" ]]; then
        pacman -Sy --needed --noconfirm curl gnupg jq base-devel git reflector

        configurar_chaotic_aur
        permitir_sudo_pacman_temporario
        instalar_yay

    elif [[ "$PKG_MGR" == "dnf" ]]; then
        dnf install -y curl gnupg2 jq tar gcc gcc-c++ make dnf-plugins-core

        if [[ "$OS_FAMILY" == "rhel" ]]; then
            dnf install -y epel-release
            dnf config-manager --set-enabled crb || true
            curl -sL https://download.docker.com/linux/centos/docker-ce.repo -o /etc/yum.repos.d/docker-ce.repo
            curl -sL "https://packages.microsoft.com/config/rhel/${RHEL_VERSION}/prod.repo" -o /etc/yum.repos.d/msprod.repo
        else
            curl -sL https://download.docker.com/linux/fedora/docker-ce.repo -o /etc/yum.repos.d/docker-ce.repo
            # A Microsoft não publica repositório "prod" próprio para Fedora;
            # o repositório do RHEL 9 é o substituto oficialmente indicado por eles.
            curl -sL https://packages.microsoft.com/config/rhel/9/prod.repo -o /etc/yum.repos.d/msprod.repo
        fi

        rpm --import https://packages.microsoft.com/keys/microsoft.asc
        cat <<EOF > /etc/yum.repos.d/vscode.repo
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

    else
        install -m 0755 -d /etc/apt/keyrings
        apt install -y ca-certificates curl gnupg ufw gufw

        curl -fsSL "https://download.docker.com/linux/${DOCKER_DISTRO}/gpg" -o /etc/apt/keyrings/docker.asc
        chmod a+r /etc/apt/keyrings/docker.asc
        cat <<EOF > /etc/apt/sources.list.d/docker.sources
Types: deb
Architectures: $ARCH
URIs: https://download.docker.com/linux/${DOCKER_DISTRO}
Suites: $BASE_CODENAME
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

        if [[ "$MS_REPO_SUPPORTED" == "1" ]]; then
            curl -sSL -O "https://packages.microsoft.com/config/${DOCKER_DISTRO}/${DISTRO_VERSION}/packages-microsoft-prod.deb"
            dpkg -i packages-microsoft-prod.deb
            rm -f packages-microsoft-prod.deb
        else
            aviso "Sem repositório oficial da Microsoft para ${DOCKER_DISTRO} ${DISTRO_VERSION}: msodbcsql/mssql-tools serão pulados mais adiante."
        fi

        curl -fSsL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | tee /etc/apt/keyrings/packages.microsoft.gpg > /dev/null
        echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | tee /etc/apt/sources.list.d/vscode.list > /dev/null

        apt update
    fi
    sucesso "Repositórios configurados."
}

registrar_modulo "repositorios" "Configurar repositórios" \
    "Docker/VSCode/MS SQL (Fedora/RHEL/Debian) ou Chaotic-AUR + yay (Arch)" \
    "configurar_repositorios"
