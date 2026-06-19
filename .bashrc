# Interactive shells only.
case $- in
  *i*) ;;
  *) return ;;
esac

export OSH="$HOME/.oh-my-bash"
OSH_THEME="font"
OMB_USE_SUDO=true

plugins=(
  git
  docker
  kubectl
)

completions=(
  git
  ssh
)

aliases=(
  general
)

if [ -f /usr/share/bash-completion/bash_completion ]; then
  . /usr/share/bash-completion/bash_completion
elif [ -f /etc/bash_completion ]; then
  . /etc/bash_completion
fi

source "$OSH/oh-my-bash.sh"

path_prepend() {
  [ -d "$1" ] || return
  case ":$PATH:" in
    *":$1:"*) ;;
    *) PATH="$1:$PATH" ;;
  esac
}

path_prepend "$HOME/.local/bin"
path_prepend "$HOME/bin"
path_prepend "$HOME/.cargo/bin"
export PATH

if command -v nvim >/dev/null 2>&1; then
  export EDITOR="${EDITOR:-nvim}"
else
  export EDITOR="${EDITOR:-vim}"
fi
export VISUAL="$EDITOR"
export PAGER="${PAGER:-less}"
export LESS="-FRX"

for aliases_file in "$HOME/aliases.sh" "$HOME/dotfiles/aliases.sh"; do
  if [ -f "$aliases_file" ]; then
    . "$aliases_file"
    break
  fi
done

[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# Lazy-load nvm for faster shell startup.
export NVM_DIR="$HOME/.nvm"

_lazy_load_nvm() {
  [ -s "$NVM_DIR/nvm.sh" ] || return 1

  unset -f _lazy_load_nvm nvm node npm npx pnpm yarn corepack
  . "$NVM_DIR/nvm.sh"
  [ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
}

for cmd in nvm node npm npx pnpm yarn corepack; do
  eval "$cmd() {
    if _lazy_load_nvm; then
      $cmd \"\$@\"
    else
      command $cmd \"\$@\"
    fi
  }"
done
