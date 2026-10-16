#!/usr/bin/env bash
set -Eeuo pipefail

# Run as the desktop user, never with sudo. --config-only is useful to restore
# the configuration when all binaries and the font are already installed.
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ASSETS="$ROOT/mint"
CONFIG_ONLY=false
if [[ "${1:-}" == '--config-only' && $# -eq 1 ]]; then
  CONFIG_ONLY=true
elif (( $# != 0 )); then
  printf 'Uso: %s [--config-only]\n' "$0" >&2
  exit 2
fi

if (( EUID == 0 )); then
  printf 'Execute como usuario normal (o script pedira sudo para pacotes).\n' >&2
  exit 1
fi
if [[ ! -f "$ASSETS/alacritty/alacritty.toml" ]]; then
  printf 'Arquivos de configuracao ausentes. Execute a partir do clone completo.\n' >&2
  exit 1
fi

log() { printf '[terminal] %s\n' "$*"; }
work=''
cleanup() { [[ -z "$work" ]] || rm -rf -- "$work"; }
trap cleanup EXIT

install_packages() {
  command -v apt-get >/dev/null || { log 'Requer Linux Mint/Ubuntu com apt-get.'; exit 1; }
  command -v sudo >/dev/null || { log 'sudo nao encontrado.'; exit 1; }
  work="$(mktemp -d)"
  sudo apt-get update
  sudo apt-get install -y alacritty bash-completion bat btop curl fd-find fontconfig fzf git unzip zoxide python3
  if apt-cache show eza >/dev/null 2>&1; then
    sudo apt-get install -y eza
  fi

  # Older Mint/Ubuntu repositories may not package eza or fastfetch.
  if ! command -v eza >/dev/null; then
    case "$(uname -m)" in
      x86_64|aarch64) arch="$(uname -m)" ;;
      *) log 'eza: arquitetura nao suportada.'; exit 1 ;;
    esac
    curl -fL --retry 3 -o "$work/eza.tar.gz" "https://github.com/eza-community/eza/releases/latest/download/eza_${arch}-unknown-linux-gnu.tar.gz"
    tar -xzf "$work/eza.tar.gz" -C "$work" eza
    install -Dm755 "$work/eza" "$HOME/.local/bin/eza"
  fi
  if ! command -v fastfetch >/dev/null; then
    if apt-cache show fastfetch >/dev/null 2>&1; then
      sudo apt-get install -y fastfetch
    else
      case "$(uname -m)" in
        x86_64) arch=amd64 ;;
        aarch64) arch=aarch64 ;;
        *) log 'fastfetch: arquitetura nao suportada.'; exit 1 ;;
      esac
      curl -fL --retry 3 -o "$work/fastfetch.deb" "https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-${arch}.deb"
      sudo apt-get install -y "$work/fastfetch.deb"
    fi
  fi

  # Zellij is not available in all Mint repositories; pin the version whose
  # KDL keybindings are included in this repository.
  if [[ ! -x /usr/local/bin/zellij ]] || [[ "$(/usr/local/bin/zellij --version)" != 'zellij 0.45.0' ]]; then
    case "$(uname -m)" in
      x86_64) arch=x86_64 ;;
      aarch64) arch=aarch64 ;;
      *) log 'Zellij: arquitetura nao suportada.'; exit 1 ;;
    esac
    curl -fL --retry 3 -o "$work/zellij.tar.gz" "https://github.com/zellij-org/zellij/releases/download/v0.45.0/zellij-${arch}-unknown-linux-musl.tar.gz"
    curl -fL --retry 3 -o "$work/zellij.sha256sum" "https://github.com/zellij-org/zellij/releases/download/v0.45.0/zellij-${arch}-unknown-linux-musl.sha256sum"
    tar -xzf "$work/zellij.tar.gz" -C "$work" zellij
    read -r expected_hash _ < "$work/zellij.sha256sum"
    printf '%s  %s\n' "$expected_hash" "$work/zellij" | sha256sum -c -
    sudo install -m755 "$work/zellij" /usr/local/bin/zellij
  fi

  if ! fc-list : family | grep -F 'CaskaydiaMono Nerd Font' >/dev/null; then
    curl -fL --retry 3 -o "$work/CascadiaMono.zip" 'https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/CascadiaMono.zip'
    mkdir -p "$work/font" "$HOME/.local/share/fonts"
    unzip -q "$work/CascadiaMono.zip" -d "$work/font"
    for style in Regular Bold Italic BoldItalic; do
      install -m644 "$work/font/CaskaydiaMonoNerdFont-${style}.ttf" "$HOME/.local/share/fonts/"
    done
    fc-cache -f "$HOME/.local/share/fonts"
  fi
}

# Replace only when content differs, keeping a timestamped backup of the
# previous file. Existing symlinks are not followed/overwritten.
install_config() {
  local source="$1" destination="$2" backup
  mkdir -p -- "$(dirname -- "$destination")"
  if [[ -L "$destination" ]]; then
    log "Link simbolico preservado, ajuste manualmente: $destination"
    return
  fi
  if [[ -f "$destination" ]] && cmp -s -- "$source" "$destination"; then
    return
  fi
  if [[ -e "$destination" ]]; then
    backup="${destination}.backup.$(date +%Y%m%d-%H%M%S)"
    while [[ -e "$backup" ]]; do backup="${backup}.1"; done
    cp -p -- "$destination" "$backup"
    log "Backup: $backup"
  fi
  install -m644 -- "$source" "$destination"
  log "Instalado: $destination"
}

# A managed block leaves the notebook's own Bash settings intact.
append_once() {
  local file="$1" marker="$2" line="$3"
  if [[ -L "$file" ]]; then
    log "Link simbolico preservado, ajuste manualmente: $file"
    return
  fi
  touch -- "$file"
  if ! grep -Fq -- "$marker" "$file"; then
    printf '\n# %s\n%s\n' "$marker" "$line" >> "$file"
    log "Ativado em $file"
  fi
}

if [[ "$CONFIG_ONLY" == false ]]; then
  install_packages
fi

for name in shared.toml theme.toml font.toml font-size.toml; do
  install_config "$ASSETS/alacritty/$name" "$HOME/.config/alacritty/$name"
done
if command -v alacritty >/dev/null && [[ "$(alacritty --version)" =~ ^alacritty[[:space:]]0\.13\. ]]; then
  install_config "$ASSETS/alacritty/shared-legacy.toml" "$HOME/.config/alacritty/shared-legacy.toml"
  install_config "$ASSETS/alacritty/alacritty-legacy.toml" "$HOME/.config/alacritty/alacritty.toml"
else
  install_config "$ASSETS/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
fi
install_config "$ASSETS/zellij/config.kdl" "$HOME/.config/zellij/config.kdl"
install_config "$ASSETS/zellij/themes/matte-black.kdl" "$HOME/.config/zellij/themes/matte-black.kdl"
install_config "$ASSETS/bash/rc" "$HOME/.config/dotfiles-terminal/bashrc"
install_config "$ASSETS/bash/inputrc" "$HOME/.config/dotfiles-terminal/inputrc"
install_config "$ASSETS/btop/themes/matte-black.theme" "$HOME/.config/btop/themes/matte-black.theme"
install_config "$ASSETS/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"
append_once "$HOME/.bashrc" 'dotfiles-terminal: Bash' '[[ -f "$HOME/.config/dotfiles-terminal/bashrc" ]] && source "$HOME/.config/dotfiles-terminal/bashrc"'
append_once "$HOME/.inputrc" 'dotfiles-terminal: Readline' '$include ~/.config/dotfiles-terminal/inputrc'

# btop's own settings can differ across versions; set just its theme.
if [[ ! -L "$HOME/.config/btop/btop.conf" ]]; then
  mkdir -p "$HOME/.config/btop"
  if [[ ! -e "$HOME/.config/btop/btop.conf" ]]; then
    printf 'color_theme = "matte-black"\n' > "$HOME/.config/btop/btop.conf"
  fi
  if ! grep -Eq '^color_theme[[:space:]]*=[[:space:]]*"matte-black"' "$HOME/.config/btop/btop.conf"; then
    backup="$HOME/.config/btop/btop.conf.backup.$(date +%Y%m%d-%H%M%S)"
    while [[ -e "$backup" ]]; do backup="${backup}.1"; done
    cp -p -- "$HOME/.config/btop/btop.conf" "$backup"
    if grep -Eq '^color_theme[[:space:]]*=' "$HOME/.config/btop/btop.conf"; then
      python3 - "$HOME/.config/btop/btop.conf" <<'PY'
from pathlib import Path
import re
import sys
p = Path(sys.argv[1])
p.write_text(re.sub(r'^color_theme\s*=.*$', 'color_theme = "matte-black"', p.read_text(), count=1, flags=re.M))
PY
    else
      printf '\ncolor_theme = "matte-black"\n' >> "$HOME/.config/btop/btop.conf"
    fi
  fi
fi

# Cinnamon reads the terminal command from this schema; do not alter desktop
# keybindings (Ctrl+Alt+T already uses the default terminal on Mint).
if [[ "$CONFIG_ONLY" == false ]] && command -v gsettings >/dev/null &&
   gsettings list-schemas | grep -Fxq 'org.cinnamon.desktop.default-applications.terminal'; then
  gsettings set org.cinnamon.desktop.default-applications.terminal exec 'alacritty'
  if gsettings list-keys org.cinnamon.desktop.default-applications.terminal | grep -Fxq 'exec-arg'; then
    gsettings set org.cinnamon.desktop.default-applications.terminal exec-arg ''
  fi
fi

log 'Pronto. Feche e abra o Alacritty para carregar Zellij e o novo Bash.'
