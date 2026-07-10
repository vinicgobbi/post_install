#!/usr/bin/env bash
# ==========================================
# UI: cores, mensagens, prompts e menu interativo
# ==========================================

VERDE='\033[0;32m'
AMARELO='\033[1;33m'
VERMELHO='\033[0;31m'
AZUL='\033[0;34m'
CINZA='\033[1;30m'
NEGRITO='\033[1m'
NC='\033[0m'

info()    { echo -e "${AMARELO}[*] $1${NC}"; }
sucesso() { echo -e "${VERDE}[+] $1${NC}"; }
aviso()   { echo -e "${AZUL}[!] $1${NC}"; }
erro()    { echo -e "${VERMELHO}[-] $1${NC}"; exit 1; }

# Imprime "[atual/total] título" para marcar o progresso dos módulos selecionados.
passo() {
    local atual="$1" total="$2" titulo="$3"
    echo -e "${NEGRITO}${AZUL}[${atual}/${total}]${NC} ${titulo}"
}

banner() {
    echo -e "${NEGRITO}${VERDE}"
    echo "=============================================="
    echo "   POST-INSTALL SETUP"
    echo "=============================================="
    echo -e "${NC}"
}

# Trap amigável para Ctrl+C.
trap_cancelamento() {
    trap 'echo -e "\n${VERMELHO}[-] Cancelado pelo usuário.${NC}"; exit 130' INT
}

# Trap para erros não tratados (fora das chamadas explícitas a erro()),
# mostrando o comando e a linha que falharam.
trap_erro_inesperado() {
    trap 'echo -e "${VERMELHO}[-] Falha inesperada (linha $LINENO): $BASH_COMMAND${NC}"' ERR
}

# Pergunta s/N genérica. Retorna 0 (sim) ou 1 (não).
confirmar() {
    local pergunta="$1"
    local resposta
    read -rp "$(echo -e "${AMARELO}[?] ${pergunta} [s/N]: ${NC}")" resposta
    [[ "$resposta" =~ ^[sSyY]$ ]]
}

# Pergunta o usuário alvo do sistema, sem valor padrão, validando que existe.
perguntar_usuario() {
    local nome
    while true; do
        read -rp "$(echo -e "${AMARELO}[?] Para qual usuário do sistema devo configurar o ambiente? ${NC}")" nome
        if [[ -z "$nome" ]]; then
            aviso "Digite um nome de usuário."
            continue
        fi
        if id -u "$nome" &>/dev/null; then
            echo "$nome"
            return 0
        fi
        aviso "Usuário '$nome' não existe neste sistema. Tente novamente."
    done
}

# ------------------------------------------------------------------
# Menu de checklist interativo em bash puro (sem whiptail/dialog).
# Uso: menu_checklist "titulo" nome_array_ids nome_array_titulos nome_array_descricoes nome_array_selecionados
# Preenche nome_array_selecionados (mesmo tamanho, "1"/"0") com a escolha do usuário.
# Se stdin não for um terminal, marca tudo como selecionado e retorna sem interação.
# ------------------------------------------------------------------
menu_checklist() {
    local titulo="$1"
    local -n _ids="$2"
    local -n _titulos="$3"
    local -n _descs="$4"
    local -n _sel="$5"

    local n="${#_ids[@]}"
    local i cursor=0

    # Por padrão tudo vem marcado.
    for ((i = 0; i < n; i++)); do _sel[i]=1; done

    if [[ ! -t 0 || ! -t 1 ]]; then
        aviso "Entrada não é um terminal interativo: executando todos os módulos automaticamente."
        return 0
    fi

    local tecla
    while true; do
        clear
        echo -e "${NEGRITO}${titulo}${NC}"
        echo -e "${CINZA}↑/↓ mover   espaço alterna   a marca/desmarca tudo   enter confirma${NC}"
        echo
        for ((i = 0; i < n; i++)); do
            local marca=" "
            [[ "${_sel[i]}" == "1" ]] && marca="x"
            local linha="[$marca] ${_titulos[i]}"
            if ((i == cursor)); then
                echo -e "${VERDE}> ${linha}${NC} ${CINZA}- ${_descs[i]}${NC}"
            else
                echo -e "  ${linha} ${CINZA}- ${_descs[i]}${NC}"
            fi
        done

        IFS= read -rsn1 tecla || tecla=''
        case "$tecla" in
            $'\x1b')
                read -rsn2 -t 0.01 tecla2 || true
                case "$tecla2" in
                    '[A') if ((cursor > 0)); then cursor=$((cursor - 1)); fi ;;
                    '[B') if ((cursor < n - 1)); then cursor=$((cursor + 1)); fi ;;
                esac
                ;;
            ' ')
                if [[ "${_sel[cursor]}" == "1" ]]; then _sel[cursor]=0; else _sel[cursor]=1; fi
                ;;
            'a'|'A')
                local todos_marcados=1
                for ((i = 0; i < n; i++)); do [[ "${_sel[i]}" == "0" ]] && todos_marcados=0; done
                for ((i = 0; i < n; i++)); do _sel[i]=$((1 - todos_marcados)); done
                ;;
            '')
                clear
                return 0
                ;;
        esac
    done
}

resumo_final() {
    local -n _executados="$1"
    local minutos=$((SECONDS / 60))
    local segundos=$((SECONDS % 60))

    echo
    echo -e "${NEGRITO}${VERDE}================ RESUMO ================${NC}"
    for item in "${_executados[@]}"; do
        echo -e "  ${VERDE}✓${NC} $item"
    done
    echo -e "${NEGRITO}Tempo total: ${minutos}m${segundos}s${NC}"
    echo -e "${NEGRITO}${VERDE}=========================================${NC}"
}
