#!/usr/bin/env zsh

set -e

# =============================================================================
# Zsh Environment Setup Script
# =============================================================================

info()  { print -P "%F{green}✓%f %B$1%f" }
warn()  { print -P "%F{yellow}!%f %B$1%f" }
err()   { print -P "%F{red}✗%f %B$1%f" >&2; exit 1 }
step()  { print -P "\n%B==> %f%F{cyan}$1%f" }

# ---------------------------------------------------------------------------
# 1. Homebrew (Linuxbrew)
# ---------------------------------------------------------------------------
step "Homebrew"
if (( ! ${+commands[brew]} )); then
  print "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
else
  info "Homebrew already installed"
fi

# ---------------------------------------------------------------------------
# 2. Core utilities (bat, eza, zoxide, fzf, fd, ripgrep)
# ---------------------------------------------------------------------------
step "Core utilities"
brew install bat eza zoxide fzf fd ripgrep 2>/dev/null || info "Some tools may already be installed"

# ---------------------------------------------------------------------------
# 3. Starship prompt
# ---------------------------------------------------------------------------
step "Starship"
if (( ! ${+commands[starship]} )); then
  brew install starship
else
  info "Starship already installed"
fi

# ---------------------------------------------------------------------------
# 4. Mise (tool version manager)
# ---------------------------------------------------------------------------
step "Mise"
if (( ! ${+commands[mise]} )); then
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
if (( ! ${+commands[pnpm]} )); then
  corepack enable
  corepack prepare pnpm@latest --activate
else
  info "pnpm already installed"
fi

# ---------------------------------------------------------------------------
# 8. Bun
# ---------------------------------------------------------------------------
step "Bun"
if (( ! ${+commands[unzip]} )); then
  brew install unzip
fi
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
if (( ! ${+commands[tv]} )); then
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
# 11. Deploy zsh config files
# ---------------------------------------------------------------------------
step "Deploying zsh configuration"
ZDOTDIR_TARGET="${ZDOTDIR:-$HOME/.config/zsh}"
mkdir -p "$ZDOTDIR_TARGET"

REPO="DevAntonioJorge/sh-conf"
BRANCH="main"
RAW="https://raw.githubusercontent.com/$REPO/$BRANCH"

for f in .zshrc aliases.zsh zoxide.zsh; do
  if [[ ! -f "$ZDOTDIR_TARGET/$f" ]]; then
    curl -fsSL "$RAW/$f" -o "$ZDOTDIR_TARGET/$f"
    info "Downloaded $f"
  else
    info "$f already exists, skipping"
  fi
done

# Ensure ZDOTDIR is set in .zshenv so zsh picks it up on startup
if [[ ! -f "$HOME/.zshenv" ]] || ! grep -q "ZDOTDIR" "$HOME/.zshenv" 2>/dev/null; then
  print "export ZDOTDIR=\"$ZDOTDIR_TARGET\"" >> "$HOME/.zshenv"
  info "ZDOTDIR set in ~/.zshenv"
else
  info "ZDOTDIR already set in ~/.zshenv"
fi

# ---------------------------------------------------------------------------
# 12. Add PATH exports to .zshrc if not present
# ---------------------------------------------------------------------------
step "Verifying PATH exports"
ZSHRC="$ZDOTDIR_TARGET/.zshrc"
touch "$ZSHRC"
for p in \
  'export PATH=$HOME/.opencode/bin:$PATH' \
  'export PATH=$HOME/.local/bin:$PATH' \
  'export PATH=$HOME/.cargo/bin:$PATH' \
  'export PNPM_HOME="$HOME/.local/share/pnpm"' \
  'export PATH="$PNPM_HOME:$PATH"' \
  'export BUN_INSTALL="$HOME/.bun"' \
  'export PATH="$BUN_INSTALL/bin:$PATH"'
do
  if ! grep -qF "$p" "$ZSHRC" 2>/dev/null; then
    print "$p" >> "$ZSHRC"
    info "Added: $p"
  fi
done

# ---------------------------------------------------------------------------
# 13. Summary
# ---------------------------------------------------------------------------
step "Done!"
print ""
print "Installed:"
print "  • Homebrew"
print "  • bat, eza, zoxide, fzf, fd, ripgrep"
print "  • Starship prompt"
print "  • Mise"
print "  • Atuin"
print "  • NVM"
print "  • pnpm"
print "  • Bun"
print "  • Television (tv)"
print "  • Zinit + plugins"
print ""
print "Config directory: $ZDOTDIR_TARGET"
print ""
print "Restart your shell with:  exec zsh"
