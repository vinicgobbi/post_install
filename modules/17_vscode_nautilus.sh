#!/usr/bin/env bash

instalar_vscode_gerenciador_arquivos() {
    if [[ "$DESKTOP_ENV" == "kde" ]]; then
        info "Ambiente Plasma detectado: adicionando 'Abrir com o VSCode' ao menu de contexto do Dolphin..."

        mkdir -p /usr/share/kio/servicemenus
        cat > /usr/share/kio/servicemenus/vscode-open-with.desktop <<'EOF'
[Desktop Entry]
Type=Service
X-KDE-ServiceTypes=KonqPopupMenu/Plugin
MimeType=all/allfiles;inode/directory;
Actions=openWithCode;

[Desktop Action openWithCode]
Name=Abrir com o VSCode
Icon=code
Exec=code %U
EOF

        command -v kbuildsycoca6 >/dev/null 2>&1 && kbuildsycoca6 --noincremental >/dev/null 2>&1
        command -v kbuildsycoca5 >/dev/null 2>&1 && kbuildsycoca5 --noincremental >/dev/null 2>&1

        sucesso "Item 'Abrir com o VSCode' adicionado ao Dolphin."
        return
    fi

    info "Instalando extensão do VSCode para o Nautilus..."

    if [[ "$PKG_MGR" == "dnf" ]]; then
        dnf install -y nautilus-python python3-gobject
    else
        apt-get install -y python3-nautilus python3-gi
    fi

    executar_como_usuario "
  rm -rf /tmp/vscode_nautilus
  git clone https://github.com/vinicgobbi/vscode_nautilus.git /tmp/vscode_nautilus
  bash /tmp/vscode_nautilus/install.sh
"
    sucesso "Extensão do VSCode para o Nautilus instalada."
}

registrar_modulo "vscode_nautilus" "Extensão VSCode no gerenciador de arquivos" \
    "Adiciona 'Abrir com o VSCode' ao menu de contexto (Nautilus no GNOME, Dolphin no Plasma)" \
    "instalar_vscode_gerenciador_arquivos"
