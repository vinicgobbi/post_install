#!/usr/bin/env bash

configurar_usuario() {
    info "Aplicando configurações locais para $USER_NAME..."
    usermod -aG docker "$USER_NAME"
    chsh -s "$(command -v zsh)" "$USER_NAME"

    executar_como_usuario "
  # Git Credential Manager
  git-credential-manager configure
  git config --global credential.credentialStore secretservice

  # FNM (download do binário, sem tocar no shell ainda) e o clone+bootstrap
  # dos dotfiles (que cuida de Oh My Zsh, plugins, tema, fontes e config do
  # Solaar) não dependem um do outro: rodam em paralelo em vez de em série.
  ( curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell ) &
  pid_fnm=\$!
  ( rm -rf /tmp/dotfiles && git clone https://github.com/vinicgobbi/Dotfiles.git /tmp/dotfiles && bash /tmp/dotfiles/bootstrap.sh ) &
  pid_dotfiles=\$!
  wait \"\$pid_fnm\" \"\$pid_dotfiles\"

  # Node LTS via FNM (agora que o binário já foi baixado acima)
  export PATH=\"\$HOME/.local/share/fnm:\$PATH\"
  eval \"\$(fnm env --shell zsh)\"

  fnm install --lts
  fnm default \$(fnm current)

  # Injeta a inicialização do fnm explicitamente no .zshrc (precisa rodar
  # depois do Oh My Zsh, que é quem cria/substitui o ~/.zshrc)
  echo 'export PATH=\"\$HOME/.local/share/fnm:\$PATH\"' >> ~/.zshrc
  echo 'eval \"\$(fnm env --shell zsh)\"' >> ~/.zshrc

  # Repositório Dotfiles já clonado e aplicado (oh-my-zsh, plugins, tema,
  # fontes, config do Solaar e papel de parede) pelo bootstrap.sh acima.

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

  # Aplicação das configurações visuais: GNOME via gsettings, Plasma via plasma-apply-colorscheme
  if [[ \"$DESKTOP_ENV\" == \"kde\" ]]; then
      command -v plasma-apply-colorscheme >/dev/null 2>&1 && plasma-apply-colorscheme BreezeDark >/dev/null 2>&1
      true
  else
      if [[ \"$ID\" != \"ubuntu\" ]]; then
          gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' && gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
      fi
      gsettings set org.gnome.desktop.interface icon-theme \"Yaru-dark\" 2>/dev/null || true
  fi
"
    sucesso "Ambiente de usuário configurado."
}

registrar_modulo "ambiente_usuario" "Configurar ambiente do usuário" \
    "Zsh, Oh My Zsh, fnm/Node, dotfiles e ajustes visuais (GNOME ou Plasma, conforme detectado)" \
    "configurar_usuario"
