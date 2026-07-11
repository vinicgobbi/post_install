#!/usr/bin/env bash

instalar_claude_code() {
    info "Instalando o Claude Code..."

    executar_como_usuario "
  curl -fsSL https://claude.ai/install.sh | bash
"
    sucesso "Claude Code instalado para $USER_NAME."
}

registrar_modulo "claude_code" "Instalar Claude Code" \
    "CLI oficial da Anthropic para desenvolvimento assistido por IA no terminal" \
    "instalar_claude_code"
