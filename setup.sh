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
# 1. Homebrew (Linuxbrew)
# ---------------------------------------------------------------------------
step "Homebrew"
if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
else
  info "Homebrew already installed"
fi

# Ensure brew is in PATH
if [[ -f /home/linuxbrew/.linuxbrew/bin/brew ]]; then
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# ---------------------------------------------------------------------------
# 2. Core utilities (bat, eza, zoxide, fzf, fd, ripgrep, unzip)
# ---------------------------------------------------------------------------
step "Core utilities"
brew install bat eza zoxide fzf fd ripgrep unzip 2>/dev/null || info "Some tools may already be installed"

# ---------------------------------------------------------------------------
# 3. Starship prompt
# ---------------------------------------------------------------------------
step "Starship"
if ! command -v starship &>/dev/null; then
  brew install starship
else
  info "Starship already installed"
fi

# ---------------------------------------------------------------------------
# 4. Mise (tool version manager)
# ---------------------------------------------------------------------------
step "Mise"
if ! command -v mise &>/dev/null; then
  brew install mise
else
  info "Mise already installed"
fi

# ---------------------------------------------------------------------------
# 5. Atuin (shell history)
# ---------------------------------------------------------------------------
step "Atuin"
if [[ ! -d "$HOME/.atuin" ]]; then
  curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh | bash
else
  info "Atuin already installed"
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
# 9. Television (tv) — fuzzy finder
# ---------------------------------------------------------------------------
step "Television (tv)"
if ! command -v tv &>/dev/null; then
  brew install television
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
)
for p in "${PATH_EXPORTS[@]}"; do
  if ! grep -qF "$p" "$ZSHRC" 2>/dev/null; then
    echo "$p" >> "$ZSHRC"
    info "Added: $p"
  fi
done

# ---------------------------------------------------------------------------
# 12. Summary
# ---------------------------------------------------------------------------
step "Done!"
echo ""
echo "Installed:"
echo "  • Homebrew"
echo "  • bat, eza, zoxide, fzf, fd, ripgrep"
echo "  • Starship prompt"
echo "  • Mise"
echo "  • Atuin"
echo "  • NVM"
echo "  • pnpm"
echo "  • Bun"
echo "  • Television (tv)"
echo "  • Zinit + plugins"
echo ""
echo "Config directory: $ZDOTDIR_TARGET"
echo ""
echo "Restart your shell with:  exec zsh"
