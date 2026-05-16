export EDITOR=nvim


source $HOME/.local/share/zinit/zinit.git/zinit.zsh

zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions

autoload -Uz compinit && compinit
zinit cdreplay -q

export PATH=$HOME/.opencode/bin:$PATH
export PATH=$HOME/.local/bin:$PATH
export PATH=$HOME/.cargo/bin:$PATH
export NVM_DIR="$HOME/.nvm"
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

plugins=(git zoxide starship)

[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
[[ -f "$ZDOTDIR/zoxide.zsh" ]] && source "$ZDOTDIR/zoxide.zsh"
[[ -f "$ZDOTDIR/aliases.zsh" ]] && source "$ZDOTDIR/aliases.zsh"

. "$HOME/.atuin/bin/env"
eval "$(atuin init zsh)"
eval "$(starship init zsh)"
eval "$(tv init zsh)"
eval "$(/home/aj/.local/bin/mise activate zsh)"

# bun completions
[ -s "/home/aj/.bun/_bun" ] && source "/home/aj/.bun/_bun"
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"


zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust
