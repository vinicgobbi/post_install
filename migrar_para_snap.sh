#!/usr/bin/env bash
# ==========================================
# Migração de apps já instalados (Flatpak/apt) para Snap
# ==========================================
# Script independente do setup.sh, para rodar numa máquina que já foi
# configurada e tem essas apps instaladas em outro formato. Pergunta
# interativamente quais apps migrar (nem sempre serão todas) e, para cada
# uma escolhida: desinstala a versão atual e instala a versão em Snap.
#
# Uso: sudo ./migrar_para_snap.sh
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/lib/ui.sh"
source "$SCRIPT_DIR/lib/os_detect.sh"
source "$SCRIPT_DIR/lib/utils.sh"
source "$SCRIPT_DIR/config.sh"

banner
echo -e "${NEGRITO}${AZUL}   MIGRAÇÃO PARA SNAP${NC}"
echo

if [ "$EUID" -ne 0 ]; then
    erro "Execute este script como root (sudo)."
fi

trap_cancelamento
trap_erro_inesperado

detectar_sistema
mensagem_sistema_detectado

if [[ "$ID" != "ubuntu" ]]; then
    erro "Esta migração é específica para Ubuntu (sistema atual: $PRETTY_NAME)."
fi

aviso "Isto desinstala a versão atual (Flatpak/apt) de cada app escolhido e"
aviso "instala a versão em Snap no lugar. Dados de apps Flatpak em ~/.var/app/"
aviso "não são apagados automaticamente, mas também não são migrados para o"
aviso "Snap (perfis/configurações precisarão ser reconfigurados manualmente)."
echo

# --- Monta o checklist a partir de SNAP_MIGRACAO ---
declare -a APP_IDS APP_TITULOS APP_DESCS APP_SEL
for entrada in "${SNAP_MIGRACAO[@]}"; do
    IFS='|' read -r titulo tipo valor snap_nome classic <<< "$entrada"
    APP_IDS+=("$snap_nome")
    APP_TITULOS+=("$titulo")
    if [[ "$tipo" == "flatpak" ]]; then
        APP_DESCS+=("Flatpak ($valor) -> Snap ($snap_nome)")
    else
        APP_DESCS+=("apt ($valor) -> Snap ($snap_nome)")
    fi
done

menu_checklist "Quais apps deseja migrar para Snap? (desmarque as que não quer mexer)" \
    APP_IDS APP_TITULOS APP_DESCS APP_SEL

SELECIONADOS=()
for ((i = 0; i < ${#APP_IDS[@]}; i++)); do
    [[ "${APP_SEL[i]}" == "1" ]] && SELECIONADOS+=("${SNAP_MIGRACAO[i]}")
done

if [[ "${#SELECIONADOS[@]}" -eq 0 ]]; then
    aviso "Nenhum app selecionado. Nada a fazer."
    exit 0
fi

echo
info "Apps selecionados para migração:"
for entrada in "${SELECIONADOS[@]}"; do
    IFS='|' read -r titulo _ _ _ _ <<< "$entrada"
    echo "  - $titulo"
done
echo

if [[ -t 0 ]] && ! confirmar "Confirmar a migração dos apps acima para Snap?"; then
    aviso "Operação cancelada pelo usuário."
    exit 0
fi

comando_existe snap || { info "Instalando snapd..."; apt install -y snapd; }

for entrada in "${SELECIONADOS[@]}"; do
    IFS='|' read -r titulo tipo valor snap_nome classic <<< "$entrada"

    info "Migrando $titulo..."

    if [[ "$tipo" == "flatpak" ]]; then
        if flatpak list --app --columns=application 2>/dev/null | grep -qx "$valor"; then
            flatpak uninstall -y "$valor" || aviso "Falha ao remover o Flatpak $valor (continuando)."
        else
            aviso "$titulo não está instalado via Flatpak neste sistema; pulando desinstalação."
        fi
    else
        if dpkg -s "$valor" &>/dev/null; then
            apt remove -y "$valor" || aviso "Falha ao remover o pacote apt $valor (continuando)."
        else
            aviso "$titulo não está instalado via apt ($valor) neste sistema; pulando desinstalação."
        fi
    fi

    flags=()
    [[ "$classic" == "classic" ]] && flags=(--classic)
    snap install "$snap_nome" "${flags[@]}"

    sucesso "$titulo migrado para Snap."
done

echo
sucesso "Migração concluída."
info "Pode ser necessário reabrir a sessão para os atalhos/menu de apps atualizarem."
