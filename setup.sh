#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Carrega bibliotecas, configuração e módulos ---
source "$SCRIPT_DIR/lib/ui.sh"
source "$SCRIPT_DIR/lib/os_detect.sh"
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/config.sh"
for _modulo in "$SCRIPT_DIR"/modules/*.sh; do
    source "$_modulo"
done
unset _modulo

banner

# --- Verificações iniciais ---
if [ "$EUID" -ne 0 ]; then
    erro "Execute este script como root (sudo)."
fi

export DEBIAN_FRONTEND=noninteractive

trap_cancelamento
trap_erro_inesperado

# --- Identificação do sistema ---
detectar_sistema
mensagem_sistema_detectado

# --- Usuário alvo ---
USER_NAME=$(perguntar_usuario)
info "Configuração será aplicada para: $USER_NAME"

# --- Seleção de módulos ---
declare -a MOD_SEL
menu_checklist "Escolha o que deseja executar (o script já vem com tudo marcado):" \
    MOD_IDS MOD_TITLES MOD_DESCS MOD_SEL

SELECIONADOS_FUNCS=()
SELECIONADOS_TITULOS=()
for ((i = 0; i < ${#MOD_IDS[@]}; i++)); do
    if [[ "${MOD_SEL[i]}" == "1" ]]; then
        SELECIONADOS_FUNCS+=("${MOD_FUNCS[i]}")
        SELECIONADOS_TITULOS+=("${MOD_TITLES[i]}")
    fi
done

TOTAL="${#SELECIONADOS_FUNCS[@]}"
if [[ "$TOTAL" -eq 0 ]]; then
    aviso "Nenhum módulo selecionado. Nada a fazer."
    exit 0
fi

echo
info "Módulos selecionados:"
for titulo in "${SELECIONADOS_TITULOS[@]}"; do
    echo "  - $titulo"
done
echo

if [[ -t 0 ]] && ! confirmar "Iniciar a configuração com os $TOTAL módulos acima?"; then
    aviso "Operação cancelada pelo usuário."
    exit 0
fi

# --- Execução ---
EXECUTADOS=()
for ((i = 0; i < TOTAL; i++)); do
    passo "$((i + 1))" "$TOTAL" "${SELECIONADOS_TITULOS[i]}"
    "${SELECIONADOS_FUNCS[i]}"
    EXECUTADOS+=("${SELECIONADOS_TITULOS[i]}")
done

resumo_final EXECUTADOS
