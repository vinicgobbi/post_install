#!/usr/bin/env bash
# ==========================================
# Utilitários gerais
# ==========================================

comando_existe() {
    command -v "$1" &>/dev/null
}

# Registro de módulos: cada arquivo em modules/ chama isto no final para
# se anunciar ao orquestrador (usado para montar o menu e a ordem de execução).
MOD_IDS=()
MOD_TITLES=()
MOD_DESCS=()
MOD_FUNCS=()

registrar_modulo() {
    MOD_IDS+=("$1")
    MOD_TITLES+=("$2")
    MOD_DESCS+=("$3")
    MOD_FUNCS+=("$4")
}

# Executa um bloco de shell como o usuário alvo (login shell, com $HOME correto).
executar_como_usuario() {
    su - "$USER_NAME" -c "$1"
}

# Baixa uma URL com algumas tentativas antes de desistir, para tolerar
# instabilidade de rede em downloads de repositórios/pacotes externos.
download_com_retry() {
    local url="$1" destino="$2" tentativas=3 i

    for ((i = 1; i <= tentativas; i++)); do
        if curl -fsSL --retry 2 -o "$destino" "$url"; then
            return 0
        fi
        aviso "Falha ao baixar $url (tentativa $i/$tentativas)."
    done
    erro "Não foi possível baixar $url após $tentativas tentativas."
}
