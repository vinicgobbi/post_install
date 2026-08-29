#!/usr/bin/env bash
# ==========================================
# Detecção de sistema operacional
# ==========================================
# Define, ao final de detectar_sistema:
#   OS_FAMILY        fedora | rhel | arch | debian
#   PKG_MGR          dnf | pacman | apt
#   ID / PRETTY_NAME vindos de /etc/os-release
#   RHEL_VERSION     (só família rhel)
#   ARCH             (só família debian) dpkg --print-architecture
#   BASE_CODENAME    (só família debian) codinome (jammy, bookworm, ...)
#   DISTRO_VERSION   (só família debian) versão numérica (22.04, 12, ...)
#   DOCKER_DISTRO    (só família debian) "ubuntu" ou "debian", para montar URLs do repo Docker
#   MS_REPO_SUPPORTED (só família debian) "1" se a Microsoft tem repo empacotado para essa combinação
#
# Família "arch" é restrita ao Arch puro (ID=arch) de propósito, na mesma
# linha do resto desta função: derivados (Manjaro, EndeavourOS, CachyOS...)
# não são cobertos, porque cada um diverge de formas diferentes (repos,
# versões de pacote, AUR helper padrão) e "parecer" Arch não garante que os
# módulos abaixo (Chaotic-AUR, yay) funcionem sem ajuste.

detectar_sistema() {
    . /etc/os-release

    if [[ "$ID" == "fedora" ]]; then
        OS_FAMILY="fedora"
        PKG_MGR="dnf"

    elif [[ "$ID" == "almalinux" || "$ID_LIKE" == *"rhel"* || "$ID_LIKE" == *"centos"* ]]; then
        OS_FAMILY="rhel"
        PKG_MGR="dnf"
        RHEL_VERSION=$(echo "$VERSION_ID" | cut -d '.' -f 1)

    elif [[ "$ID" == "arch" ]]; then
        OS_FAMILY="arch"
        PKG_MGR="pacman"

    elif [[ "$ID" == "ubuntu" || "$ID" == "debian" || "$ID_LIKE" == *"ubuntu"* || "$ID_LIKE" == *"debian"* ]]; then
        OS_FAMILY="debian"
        PKG_MGR="apt"
        ARCH=$(dpkg --print-architecture)
        
        # 1. Identifica se é Ubuntu ou um derivado (como o Linux Mint)
        if [[ "$ID" == "ubuntu" || "$ID_LIKE" == *"ubuntu"* ]]; then
            DOCKER_DISTRO="ubuntu"

            # 2. Descobre o codinome real do Ubuntu por trás da distro
            if [ -f /etc/upstream-release/lsb-release ]; then
                # O Mint guarda a base do Ubuntu aqui
                BASE_CODENAME=$(grep "DISTRIB_CODENAME=" /etc/upstream-release/lsb-release | cut -d= -f2)
            else
                # Fallback para Ubuntu puro ou distros que expõem direto no os-release
                BASE_CODENAME=${UBUNTU_CODENAME:-$VERSION_CODENAME}
            fi

            # 3. Valida e define as variáveis com base no Ubuntu encontrado
            case "$BASE_CODENAME" in
                bionic) DISTRO_VERSION="18.04"; MS_REPO_SUPPORTED=1 ;;
                focal)  DISTRO_VERSION="20.04"; MS_REPO_SUPPORTED=1 ;;
                jammy)  DISTRO_VERSION="22.04"; MS_REPO_SUPPORTED=1 ;;
                noble)  DISTRO_VERSION="24.04"; MS_REPO_SUPPORTED=1 ;;
                *)
                    # Versão do Ubuntu ainda sem repositório oficial "prod.repo"
                    # publicado pela Microsoft (ex.: a LTS mais recente, recém-lançada).
                    # Os pacotes msodbcsql/mssql-tools da última LTS suportada são
                    # compatíveis na prática, então usamos o repositório dela como fallback.
                    DISTRO_VERSION="24.04"
                    MS_REPO_SUPPORTED=1
                    aviso "Ubuntu $BASE_CODENAME ainda não tem repositório oficial da Microsoft; usando o repositório do Ubuntu 24.04 (compatível) para msodbcsql/mssql-tools."
                    ;;
            esac
        else
            # Debian puro e derivados diretos do Debian (ex: LMDE)
            DOCKER_DISTRO="debian"
            BASE_CODENAME=${VERSION_CODENAME:-$VERSION_ID}
            case "$BASE_CODENAME" in
                bullseye) DISTRO_VERSION="11"; MS_REPO_SUPPORTED=1 ;;
                bookworm) DISTRO_VERSION="12"; MS_REPO_SUPPORTED=1 ;;
                *)        DISTRO_VERSION="$VERSION_ID"; MS_REPO_SUPPORTED=0 ;;
            esac
        fi
    else
        erro "Distribuição não suportada: $PRETTY_NAME"
    fi
}

mensagem_sistema_detectado() {
    case "$OS_FAMILY" in
        debian)
            info "Sistema detectado: $PRETTY_NAME (Base: $DOCKER_DISTRO $DISTRO_VERSION / $BASE_CODENAME)"
            ;;
        rhel)
            info "Sistema detectado: $PRETTY_NAME (Base: RHEL $RHEL_VERSION)"
            ;;
        arch)
            info "Sistema detectado: $PRETTY_NAME (rolling release, pacman + Chaotic-AUR/yay)"
            ;;
        *)
            info "Sistema detectado: $PRETTY_NAME"
            ;;
    esac
}
