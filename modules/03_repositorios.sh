#!/usr/bin/env bash

configurar_repositorios() {
    info "Configurando repositórios (Docker, Microsoft)..."

    if [[ "$PKG_MGR" == "dnf" ]]; then
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
        apt-get install -y ca-certificates curl gnupg ufw gufw

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
    fi
    sucesso "Repositórios configurados."
}

registrar_modulo "repositorios" "Configurar repositórios" \
    "Adiciona os repositórios do Docker, VSCode e Microsoft SQL" \
    "configurar_repositorios"
