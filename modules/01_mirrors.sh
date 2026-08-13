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
            otimizar_mirrors_ubuntu
        elif [[ "$ID" == "debian" ]]; then
            info "Debian detectado. O sistema já utiliza o redirecionador global por CDN (deb.debian.org) por padrão."
        fi
    fi
}

# Monta a lista de candidatos a testar:
#   1) o pick do GeoIP da Canonical (http://mirrors.ubuntu.com/mirrors.txt —
#      tem que ser http:// simples: em algumas redes o https:// desse host
#      trava/dá timeout, mesmo com o resto da internet funcionando normal).
#      Esse endpoint devolve UMA linha só (o mirror que o GeoIP já escolheria
#      de qualquer forma) — serve de baseline garantido, não uma lista.
#   2) os mirrors do próprio país do IP público, extraídos da página de
#      mirrors do Launchpad (organizada em seções por país). É essencial:
#      testar uma amostra aleatória dentre TODOS os mirrors do mundo tem
#      grande chance de nunca incluir o mirror local de fato mais rápido
#      (confirmado na prática: um mirror brasileiro chegou a ser >5x mais
#      rápido que os que uma amostra aleatória testou).
#   3) uma amostra aleatória global do feed RSS de mirrors do Launchpad, só
#      como complemento/fallback caso a seção do país não exista ou venha
#      vazia.
# Ecoa cada candidato em stdout, uma URL por linha.
candidatos_mirror_ubuntu() {
    local geoip pais bloco

    geoip="$(curl -fsSL --max-time 5 "http://mirrors.ubuntu.com/mirrors.txt" 2>/dev/null)"
    [[ -n "$geoip" ]] && echo "$geoip"

    pais="$(curl -fsSL --max-time 5 "http://ip-api.com/line/?fields=country" 2>/dev/null)"
    if [[ -n "$pais" ]]; then
        bloco="$(curl -fsSL --max-time 12 "https://launchpad.net/ubuntu/+archivemirrors" 2>/dev/null | awk -v pais="$pais" '
            $0 ~ "<th colspan=\"2\">" pais "</th>" { dentro=1; next }
            dentro && /<tr class="head">/ { exit }
            dentro
        ')"
        grep -oE 'href="https?://[^"]+/ubuntu/"' <<< "$bloco" | sed -E 's/^href="//; s/"$//' | sort -u
    fi

    curl -fsSL --max-time 12 "https://launchpad.net/ubuntu/+archivemirrors-rss" 2>/dev/null \
        | grep -oE '<link>https?://[^<]+/ubuntu/</link>' \
        | sed -E 's|</?link>||g' \
        | sort -u \
        | shuf -n 8
}

# Testa o tempo de download do Release de cada candidato em paralelo (em vez
# de um por um) e fica com o menor tempo medido de verdade nesta rede, em vez
# de confiar em GeoIP de terceiros. Com timeout de 4s por candidato, testar
# ~10 candidatos em série custaria até ~40s; em paralelo custa só o tempo do
# candidato mais lento.
# Ecoa a URL vencedora em stdout; não ecoa nada e retorna 1 se nenhuma responder.
escolher_mirror_ubuntu_mais_rapido() {
    local candidato timeout_candidato=4
    local tmpdir melhor_url="" i=0

    tmpdir="$(mktemp -d)"

    while IFS= read -r candidato; do
        [[ -z "$candidato" ]] && continue
        i=$((i + 1))
        (
            tempo="$(curl -fsSL -o /dev/null -s -w '%{time_total}' --max-time "$timeout_candidato" \
                "${candidato%/}/dists/${BASE_CODENAME}/Release" 2>/dev/null)" &&
                [[ -n "$tempo" ]] && printf '%s %s\n' "$tempo" "$candidato" > "$tmpdir/$i"
        ) &
    done < <(candidatos_mirror_ubuntu)
    wait

    melhor_url="$(cat "$tmpdir"/* 2>/dev/null | sort -n | head -n1 | awk '{print $2}')"
    rm -rf "$tmpdir"

    [[ -z "$melhor_url" ]] && return 1
    echo "$melhor_url"
}

otimizar_mirrors_ubuntu() {
    local mirror_rapido

    # Forma "if ! var=$(cmd)" de propósito: setup.sh roda com `set -e`, e um
    # `var="$(cmd)"` solto (fora de if/||) aborta o script inteiro quando cmd
    # falha, sem mensagem clara nenhuma sobre qual módulo quebrou.
    if ! mirror_rapido="$(escolher_mirror_ubuntu_mais_rapido)"; then
        aviso "Não foi possível testar a velocidade dos mirrors (sem rede?). Mantendo o redirecionador automático (mirror://) do Ubuntu."
        mirror_rapido="mirror://mirrors.ubuntu.com/mirrors.txt"
    else
        sucesso "Mirror mais rápido nos testes: $mirror_rapido"
    fi

    local arquivo
    for arquivo in /etc/apt/sources.list /etc/apt/sources.list.d/ubuntu.sources; do
        [[ -f "$arquivo" ]] || continue
        sed -i \
            -e "s|http://archive\.ubuntu\.com/ubuntu/|${mirror_rapido}|g" \
            -e "s|http://security\.ubuntu\.com/ubuntu/|${mirror_rapido}|g" \
            -e "s|mirror://mirrors\.ubuntu\.com/mirrors\.txt|${mirror_rapido}|g" \
            "$arquivo"
    done
    sucesso "APT otimizado: repositórios apontando para o mirror com melhor tempo de resposta medido agora."
}

registrar_modulo "mirrors" "Otimizar mirrors" \
    "Ajusta o gerenciador de pacotes para baixar dos espelhos mais rápidos" \
    "otimizar_mirrors"
