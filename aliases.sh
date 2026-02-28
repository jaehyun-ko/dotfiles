# Shared aliases for Bash and Zsh.

if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first'
  alias ll='eza -lah --group-directories-first'
  alias la='eza -a --group-directories-first'
  alias lt='eza --tree --level=2 --group-directories-first'
else
  if ls --color=auto . >/dev/null 2>&1; then
    alias ls='ls --color=auto'
  fi
  alias ll='ls -alF'
  alias la='ls -A'
fi

alias l='ls -CF'
alias cls='clear'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias reload='exec "$SHELL" -l'

if grep --color=auto "" /dev/null >/dev/null 2>&1; then
  alias grep='grep --color=auto'
fi

if diff --color=auto /dev/null /dev/null >/dev/null 2>&1; then
  alias diff='diff --color=auto'
fi

alias gs='git status -sb'
alias ga='git add'
alias gb='git branch'
alias gc='git commit'
alias gca='git commit --amend'
alias gco='git checkout'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate -20'
alias gpl='git pull --rebase'
alias gp='git push'
alias gcl='git clone'

alias k='kubectl'
alias d='docker'

if command -v nvim >/dev/null 2>&1; then
  alias vi='nvim'
  alias vim='nvim'
fi
