#!/usr/bin/env bash

instalar_tailscale() {
    info "Instalando o Tailscale e o Trayscale..."

    curl -fsSL https://tailscale.com/install.sh | sh
    systemctl enable --now tailscaled

    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    flatpak install -y flathub dev.deedles.Trayscale

    tailscale set --operator="$USER_NAME"

    sucesso "Tailscale instalado e '$USER_NAME' definido como operator."
}

registrar_modulo "tailscale" "Instalar Tailscale + Trayscale" \
    "Tailscale (VPN mesh) e o cliente gráfico Trayscale via Flatpak" \
    "instalar_tailscale"
