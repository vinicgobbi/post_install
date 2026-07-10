#!/usr/bin/env bash

otimizar_mirrors() {
    info "Otimizando a seleção de espelhos (mirrors) para o gerenciador de pacotes..."
    if [[ "$PKG_MGR" == "dnf" ]]; then
        sed -i '/fastestmirror=/d' /etc/dnf/dnf.conf 2>/dev/null || true
        sed -i '/max_parallel_downloads=/d' /etc/dnf/dnf.conf 2>/dev/null || true

        echo "fastestmirror=True" >> /etc/dnf/dnf.conf
        echo "max_parallel_downloads=10" >> /etc/dnf/dnf.conf
        sucesso "DNF otimizado: fastestmirror ativado e downloads paralelos definidos para 10."
    else
        if [[ "$ID" == "ubuntu" ]]; then
            if [ -f /etc/apt/sources.list ]; then
                sed -i 's|http://archive.ubuntu.com/ubuntu/|mirror://mirrors.ubuntu.com/mirrors.txt|g' /etc/apt/sources.list
                sed -i 's|http://security.ubuntu.com/ubuntu/|mirror://mirrors.ubuntu.com/mirrors.txt|g' /etc/apt/sources.list
            fi
            if [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then
                sed -i 's|http://archive.ubuntu.com/ubuntu/|mirror://mirrors.ubuntu.com/mirrors.txt|g' /etc/apt/sources.list.d/ubuntu.sources
                sed -i 's|http://security.ubuntu.com/ubuntu/|mirror://mirrors.ubuntu.com/mirrors.txt|g' /etc/apt/sources.list.d/ubuntu.sources
            fi
            sucesso "APT otimizado: Redirecionamento geográfico inteligente ativado."
        elif [[ "$ID" == "debian" ]]; then
            info "Debian detectado. O sistema já utiliza o redirecionador global por CDN (deb.debian.org) por padrão."
        fi
    fi
}

registrar_modulo "mirrors" "Otimizar mirrors" \
    "Ajusta o gerenciador de pacotes para baixar dos espelhos mais rápidos" \
    "otimizar_mirrors"
