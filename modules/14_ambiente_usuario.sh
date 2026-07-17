#!/usr/bin/env bash

configurar_usuario() {
    info "Aplicando configurações locais para $USER_NAME..."
    usermod -aG docker "$USER_NAME"
    chsh -s "$(command -v zsh)" "$USER_NAME"

    executar_como_usuario "
  # Git Credential Manager
  git-credential-manager configure
  git config --global credential.credentialStore secretservice

  # Oh My Zsh
  curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | RUNZSH=no CHSH=no sh

  # FNM (Fast Node Manager) e Node LTS
  curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
  export PATH=\"\$HOME/.local/share/fnm:\$PATH\"
  eval \"\$(fnm env --shell zsh)\"

  fnm install --lts
  fnm default \$(fnm current)

  # Injeta a inicialização do fnm explicitamente no .zshrc
  echo 'export PATH=\"\$HOME/.local/share/fnm:\$PATH\"' >> ~/.zshrc
  echo 'eval \"\$(fnm env --shell zsh)\"' >> ~/.zshrc

  # Repositório Dotfiles (remove clone anterior para permitir reexecução do script)
  rm -rf /tmp/dotfiles
  git clone https://github.com/vinicgobbi/Dotfiles.git /tmp/dotfiles
  mkdir -p ~/.config/solaar ~/.local/share/fonts ~/.oh-my-zsh/custom

  cp -r /tmp/dotfiles/config/solaar/* ~/.config/solaar/ 2>/dev/null || true
  cp -r /tmp/dotfiles/fonts/* ~/.local/share/fonts/ 2>/dev/null || true
  cp -r /tmp/dotfiles/oh-my-zsh/custom/* ~/.oh-my-zsh/custom/ 2>/dev/null || true

  # ZSH Theme e Fontes
  sed -i 's/ZSH_THEME=\".*\"/ZSH_THEME=\"detail\"/' ~/.zshrc
  fc-cache -f -v

  # Diretório de Projetos (XDG e Bookmarks)
  if [[ \"\$LANG\" == pt_* ]]; then
      DIR_NAME=\"Projetos\"
  else
      DIR_NAME=\"Projects\"
  fi
  PROJECTS_DIR=\"\$HOME/\$DIR_NAME\"
  mkdir -p \"\$PROJECTS_DIR\"

  xdg-user-dirs-update --set PROJECTS \"\$PROJECTS_DIR\"

  BOOKMARKS_FILE=\"\$HOME/.config/gtk-3.0/bookmarks\"
  mkdir -p \"\$(dirname \"\$BOOKMARKS_FILE\")\"
  touch \"\$BOOKMARKS_FILE\"
  if ! grep -q \"file://\$PROJECTS_DIR\" \"\$BOOKMARKS_FILE\"; then
      echo \"file://\$PROJECTS_DIR\" >> \"\$BOOKMARKS_FILE\"
  fi

  # Autostart do Solaar (prioriza o .desktop do pacote nativo; usa o do Flatpak como alternativa)
  mkdir -p \"\$HOME/.config/autostart\"
  cp /usr/share/applications/solaar.desktop \"\$HOME/.config/autostart/\" 2>/dev/null || \
      cp /var/lib/flatpak/exports/share/applications/io.github.pwr_solaar.solaar.desktop \"\$HOME/.config/autostart/\" 2>/dev/null || true

  # Aplicação das configurações visuais do GNOME via gsettings
  if [[ \"$ID\" != \"ubuntu\" ]]; then
      gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' && gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
  fi
  gsettings set org.gnome.desktop.interface icon-theme \"Yaru-dark\" 2>/dev/null || true
"
    sucesso "Ambiente de usuário configurado."
}

registrar_modulo "ambiente_usuario" "Configurar ambiente do usuário" \
    "Zsh, Oh My Zsh, fnm/Node, dotfiles e ajustes visuais do GNOME" \
    "configurar_usuario"
