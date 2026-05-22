#!/usr/bin/env bash

set -euo pipefail

# =============================================================================
# Zsh Environment Setup Script
# =============================================================================

ZDOTDIR_TARGET="${ZDOTDIR:-$HOME/.config/zsh}"
REPO="DevAntonioJorge/sh-conf"
BRANCH="main"
RAW="https://raw.githubusercontent.com/${REPO}/${BRANCH}"

info()  { echo -e "\033[1;32m✓\033[0m \033[1m$1\033[0m"; }
warn()  { echo -e "\033[1;33m!\033[0m \033[1m$1\033[0m"; }
err()   { echo -e "\033[1;31m✗\033[0m \033[1m$1\033[0m" >&2; exit 1; }
step()  { echo -e "\n\033[1m==> \033[0m\033[1;36m$1\033[0m"; }

# ---------------------------------------------------------------------------
# Distro detection & package manager abstraction
# ---------------------------------------------------------------------------
PKG_MGR=""
DISTRO="generic"
:'
detect_distro() {
  if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    case "$ID" in
      opensuse-tumbleweed|opensuse) DISTRO="opensuse"; PKG_MGR="sudo zypper install -y" ;;
      arch)                         DISTRO="arch";     PKG_MGR="sudo pacman -S --noconfirm" ;;
      fedora)                       DISTRO="fedora";   PKG_MGR="sudo dnf install -y" ;;
      *)                            DISTRO="generic";  PKG_MGR="" ;;
    esac
  else
    DISTRO="generic"; PKG_MGR=""
  fi
}
'

pkg_install() {
  if [[ "$DISTRO" == "generic" ]]; then
    brew install "$@" 2>/dev/null || warn "Some packages may not have installed"
  else
    $PKG_MGR "$@"
  fi
}

is_installed() {
  if [[ "$DISTRO" == "generic" ]]; then
    command -v "$1" &>/dev/null
  else
    case "$DISTRO" in
      opensuse|fedora) rpm -q "$1" &>/dev/null ;;
      arch)            pacman -Q "$1" &>/dev/null ;;
    esac
  fi
}

detect_distro
info "Detected distro: $DISTRO"

# ---------------------------------------------------------------------------
# Check required archive utility
# ---------------------------------------------------------------------------
step "Checking for tar"
if ! command -v tar &>/dev/null; then
  info "tar not found, installing..."
  if ! pkg_install tar || ! command -v tar &>/dev/null; then
    err "tar is required but installation failed. Please install tar manually and re-run the script."
  fi
else
  info "tar is already installed"
fi

# ---------------------------------------------------------------------------
# 0. Deploy zsh config files FIRST (before ZDOTDIR is set in .zshenv)
# ---------------------------------------------------------------------------
step "Deploying zsh configuration"
mkdir -p "$ZDOTDIR_TARGET"

CONFIG_FILES=(.zshrc aliases.zsh zoxide.zsh)
for f in "${CONFIG_FILES[@]}"; do
  if [[ ! -f "$ZDOTDIR_TARGET/$f" ]]; then
    curl -fsSL "$RAW/$f" -o "$ZDOTDIR_TARGET/$f"
    info "Downloaded $f"
  else
    info "$f already exists, keeping your version"
  fi
done

# Ensure ZDOTDIR is set in .zshenv so zsh picks it up on startup
if [[ ! -f "$HOME/.zshenv" ]] || ! grep -q "ZDOTDIR" "$HOME/.zshenv" 2>/dev/null; then
  echo "export ZDOTDIR=\"$ZDOTDIR_TARGET\"" >> "$HOME/.zshenv"
  info "ZDOTDIR set in ~/.zshenv"
else
  info "ZDOTDIR already set in ~/.zshenv"
fi

# ---------------------------------------------------------------------------
# 1. Homebrew (Linuxbrew) — only on generic distros
# ---------------------------------------------------------------------------
step "Homebrew"
if [[ "$DISTRO" == "generic" ]]; then
  if ! command -v brew &>/dev/null; then
    echo "Installing Homebrew..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  else
    info "Homebrew already installed"
  fi

  if [[ -f /home/linuxbrew/.linuxbrew/bin/brew ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi
else
  info "Using native package manager ($DISTRO), skipping Homebrew"
fi

# ---------------------------------------------------------------------------
# 2. Core utilities (bat, eza, zoxide, fzf, fd, ripgrep, unzip)
# ---------------------------------------------------------------------------
step "Core utilities"
pkg_install bat eza zoxide fzf fd ripgrep unzip

# ---------------------------------------------------------------------------
# 2b. Go (golang)
# ---------------------------------------------------------------------------
step "Go"
if ! command -v go &>/dev/null; then
  info "Go not found, attempting to install via package manager"
  if ! pkg_install go && ! pkg_install golang; then
    warn "Could not install Go via package manager. Please install Go manually from https://go.dev/dl/"
  else
    info "Go installed"
  fi
else
  info "Go already installed"
fi

# Ensure GOPATH directory exists
mkdir -p "$HOME/.go"

# ---------------------------------------------------------------------------
# 3. Starship prompt
# ---------------------------------------------------------------------------
step "Starship"
if ! command -v starship &>/dev/null; then
  if [[ "$DISTRO" == "opensuse" || "$DISTRO" == "fedora" ]]; then
    curl -sS https://starship.rs/install.sh | sh -s -- --yes
  else
    pkg_install starship
  fi
  info "Starship installed"
else
  info "Starship already installed"
fi

# ---------------------------------------------------------------------------
# 4. Mise (tool version manager)
# ---------------------------------------------------------------------------
step "Mise"
if ! command -v mise &>/dev/null; then
  if [[ "$DISTRO" == "opensuse" ]]; then
    curl https://mise.run | sh
  else
    pkg_install mise
  fi
  info "Mise installed"
else
  info "Mise already installed"
fi

# ---------------------------------------------------------------------------
# 5. Atuin (shell history)
# ---------------------------------------------------------------------------
step "Atuin"
if [[ ! -d "$HOME/.atuin" ]]; then
  curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | sh -s -- --non-interactive
  info "Atuin installed"
else
  info "Atuin already installed"
fi

# Configure Atuin (daemon + autostart)
ATUIN_CONFIG_DIR="$HOME/.config/atuin"
ATUIN_CONFIG="$ATUIN_CONFIG_DIR/config.toml"
mkdir -p "$ATUIN_CONFIG_DIR"
if [[ ! -f "$ATUIN_CONFIG" ]]; then
  cat > "$ATUIN_CONFIG" <<'EOF'
auto_sync = true
update_check = true
search_mode = "fuzzy"
filter_mode = "global"
style = "compact"
inline_height = 40
show_preview = true
enter_accept = true
keymap_mode = "emacs"

[daemon]
enabled = true
autostart = true
sync_frequency = 300

[search]
filters = ["global", "host", "session", "directory"]

[stats]
common_subcommands = [
  "apt", "cargo", "composer", "dnf", "docker", "git", "go",
  "kubectl", "nix", "npm", "pnpm", "podman", "systemctl", "tmux", "yarn"
]
common_prefix = ["sudo"]
EOF
  info "Atuin config created with daemon enabled"
else
  info "Atuin config already exists"
fi

# ---------------------------------------------------------------------------
# 6. NVM
# ---------------------------------------------------------------------------
step "NVM"
if [[ ! -d "$HOME/.nvm" ]]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
else
  info "NVM already installed"
fi

# ---------------------------------------------------------------------------
# 7. pnpm
# ---------------------------------------------------------------------------
step "pnpm"
if ! command -v pnpm &>/dev/null; then
  corepack enable
  corepack prepare pnpm@latest --activate
else
  info "pnpm already installed"
fi

# ---------------------------------------------------------------------------
# 8. Bun
# ---------------------------------------------------------------------------
step "Bun"
if [[ ! -d "$HOME/.bun" ]]; then
  curl -fsSL https://bun.sh/install | bash
  export BUN_INSTALL="$HOME/.bun"
  export PATH="$BUN_INSTALL/bin:$PATH"
else
  info "Bun already installed"
fi

# ---------------------------------------------------------------------------
# 9. Television (tv) — fuzzy finder (via cargo on all distros)
# ---------------------------------------------------------------------------
step "Television (tv)"
if ! command -v tv &>/dev/null; then
  if ! command -v cargo &>/dev/null; then
    warn "cargo not found, installing Rust toolchain first..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
  fi
  cargo install television
  info "Television installed via cargo"
else
  info "Television already installed"
fi

# ---------------------------------------------------------------------------
# 10. Zinit (plugin manager)
# ---------------------------------------------------------------------------
step "Zinit"
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [[ ! -d "$ZINIT_HOME/.git" ]]; then
  mkdir -p "$ZINIT_HOME"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
  info "Zinit installed at $ZINIT_HOME"
else
  info "Zinit already installed"
fi

# ---------------------------------------------------------------------------
# 11. Add PATH exports to .zshrc if not present
# ---------------------------------------------------------------------------
step "Verifying PATH exports"
ZSHRC="$ZDOTDIR_TARGET/.zshrc"
PATH_EXPORTS=(
  'export PATH=$HOME/.opencode/bin:$PATH'
  'export PATH=$HOME/.local/bin:$PATH'
  'export PATH=$HOME/.cargo/bin:$PATH'
  'export PNPM_HOME="$HOME/.local/share/pnpm"'
  'export PATH="$PNPM_HOME:$PATH"'
  'export BUN_INSTALL="$HOME/.bun"'
  'export PATH="$BUN_INSTALL/bin:$PATH"'
  'export GOPATH="$HOME/.go"'
  'export PATH="$GOPATH/bin:$PATH"'
)
for p in "${PATH_EXPORTS[@]}"; do
  if ! grep -qF "$p" "$ZSHRC" 2>/dev/null; then
    echo "$p" >> "$ZSHRC"
    info "Added: $p"
  fi
done

# ---------------------------------------------------------------------------
# 12. Install zsh (chsh removed — run manually if needed)
# ---------------------------------------------------------------------------
step "Installing zsh"
if ! command -v zsh &>/dev/null; then
  pkg_install zsh
  info "zsh installed"
else
  info "zsh already installed"
fi

# ---------------------------------------------------------------------------
# 13. Summary
# ---------------------------------------------------------------------------
ZSH_PATH="$(command -v zsh 2>/dev/null || echo "not installed")"
CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"

step "Done!"
echo ""
echo "Detected distro: $DISTRO"
echo ""
echo "Installed:"
echo "  • Core utilities: bat, eza, zoxide, fzf, fd, ripgrep"
echo "  • Starship prompt"
echo "  • Mise"
echo "  • Atuin"
echo "  • NVM"
echo "  • pnpm"
echo "  • Bun"
echo "  • Television (tv) — via cargo"
echo "  • Zinit + plugins"
if [[ "$DISTRO" != "generic" ]]; then
  echo "  • zsh (via native package manager)"
else
  echo "  • Homebrew"
  echo "  • zsh (via brew)"
fi
echo ""
echo "Config directory: $ZDOTDIR_TARGET"
echo ""
if [[ "$CURRENT_SHELL" != "$ZSH_PATH" ]]; then
  echo "To set zsh as default shell, run manually:"
  echo "  chsh -s $(which zsh 2>/dev/null || echo '$ZSH_PATH')"
  echo ""
fi
if [[ "$DISTRO" == "opensuse" || "$DISTRO" == "fedora" ]]; then
  echo "Note: Ruby is provided by your system package manager."
  echo "  Install with: sudo zypper/dnf install ruby ruby-devel"
  echo ""
fi
echo "Restart your shell with:  exec zsh"
