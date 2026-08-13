#!/usr/bin/env bash

instalar_chrome_e_gcm() {
    info "Instalando Git Credential Manager e Google Chrome..."
    if [[ "$PKG_MGR" == "dnf" ]]; then
        GCM_URL=$(curl -sL https://api.github.com/repos/git-ecosystem/git-credential-manager/releases/latest | jq -r '.assets[] | select(.name | endswith(".tar.gz") and contains("linux-x64") and (contains("symbols") | not)) | .browser_download_url' | head -n 1)

        # GCM (tar.gz local) e Chrome (rpm) são downloads independentes: baixa
        # os dois em paralelo em vez de um atrás do outro.
        curl -sSL -o /tmp/gcm.tar.gz "$GCM_URL" &
        curl -sSL -o /tmp/chrome.rpm https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm &
        wait

        mkdir -p /usr/local/gcm
        tar -xzf /tmp/gcm.tar.gz -C /usr/local/gcm
        ln -sf /usr/local/gcm/git-credential-manager /usr/local/bin/git-credential-manager

        dnf install -y /tmp/chrome.rpm
    else
        GCM_URL=$(curl -sL https://api.github.com/repos/git-ecosystem/git-credential-manager/releases/latest | jq -r '.assets[] | select(.name | endswith(".deb") and contains("linux-x64")) | .browser_download_url' | head -n 1)

        # Mesma ideia: baixa os dois .deb em paralelo e instala ambos numa
        # única chamada do apt (evita duas resoluções de dependência).
        curl -sSL -o /tmp/gcm.deb "$GCM_URL" &
        curl -sSL -o /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb &
        wait

        apt install -y /tmp/gcm.deb /tmp/chrome.deb
    fi
    sucesso "Chrome e GCM instalados."
}

registrar_modulo "chrome_gcm" "Chrome + Git Credential Manager" \
    "Instala o Google Chrome e o Git Credential Manager" \
    "instalar_chrome_e_gcm"
