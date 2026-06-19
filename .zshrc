# Powerlevel10k instant prompt. Keep this block near the top.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""

plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  autojump
)

source "$ZSH/oh-my-zsh.sh"

# Core environment.
if command -v nvim >/dev/null 2>&1; then
  export EDITOR="${EDITOR:-nvim}"
else
  export EDITOR="${EDITOR:-vim}"
fi
export VISUAL="$EDITOR"
export PAGER="${PAGER:-less}"
export LESS="-FRX"

typeset -U path PATH
for dir in "$HOME/.local/bin" "$HOME/bin" "$HOME/.cargo/bin"; do
  [[ -d "$dir" ]] && path=("$dir" $path)
done

# Shared aliases.
for aliases_file in "$HOME/aliases.sh" "$HOME/dotfiles/aliases.sh"; do
  [[ -f "$aliases_file" ]] && source "$aliases_file" && break
done

# Local environment hooks.
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
[[ -f "$HOME/.local/bin/env" ]] && source "$HOME/.local/bin/env"

# Powerlevel10k prompt.
[[ -r "$HOME/powerlevel10k/powerlevel10k.zsh-theme" ]] && source "$HOME/powerlevel10k/powerlevel10k.zsh-theme"
[[ -f "$HOME/.p10k.zsh" ]] && source "$HOME/.p10k.zsh"

# Lazy-load nvm for faster shell startup.
export NVM_DIR="$HOME/.nvm"

_lazy_load_nvm() {
  [[ -s "$NVM_DIR/nvm.sh" ]] || return 1

  unset -f _lazy_load_nvm nvm node npm npx pnpm yarn corepack
  source "$NVM_DIR/nvm.sh"
  [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
}

for cmd in nvm node npm npx pnpm yarn corepack; do
  eval "${cmd}() {
    if _lazy_load_nvm; then
      ${cmd} \"\$@\"
    else
      command ${cmd} \"\$@\"
    fi
  }"
done
