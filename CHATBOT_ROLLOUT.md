# Chatbot Instruction: Step-1 Auto Rollout to All Servers

This document automates the **Step 1** rollout on all enabled servers:

1. `git pull --ff-only origin main`
2. `./install.sh -y`
3. `systemctl --user daemon-reload`
4. `systemctl --user restart dotfiles-auto-update.timer`

## Preconditions

- Run from the control node.
- `sync/servers.tsv` exists and enabled targets are set with `enabled=1`.
- The control node can SSH into each target (optional SSH settings loaded from `~/.config/dotfiles-sync/config.env`).

## Chatbot Execution Contract

- Continue all hosts even if some fail.
- Print per-host result and final success/failure summary.
- Exit non-zero if any host failed.

## One-shot Command (run on control node)

```bash
cd ~/dotfiles

set -euo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-$HOME/dotfiles}"
INVENTORY="${DOTFILES_SYNC_INVENTORY:-$DOTFILES_REPO/sync/servers.tsv}"
SSH_USER="${DOTFILES_SYNC_SSH_USER:-}"
SSH_PORT_DEFAULT="${DOTFILES_SYNC_SSH_PORT:-}"
SSH_IDENTITY="${DOTFILES_SYNC_SSH_IDENTITY:-}"
SELF_ID="${DOTFILES_SERVER_ID:-$(hostname -s 2>/dev/null || hostname)}"
CLONE_URL="$(git -C "$DOTFILES_REPO" remote get-url origin)"

if [[ -f "$HOME/.config/dotfiles-sync/config.env" ]]; then
  # shellcheck disable=SC1090
  source "$HOME/.config/dotfiles-sync/config.env"
fi

if [[ ! -f "$INVENTORY" ]]; then
  echo "[error] inventory not found: $INVENTORY" >&2
  exit 1
fi

fail=0

while IFS=$'\t' read -r server_id ssh_host repo_path ssh_port post_cmd enabled; do
  [[ -z "${server_id:-}" || "${server_id:0:1}" == "#" ]] && continue
  [[ "$server_id" == "server_id" ]] && continue
  [[ "${enabled:-0}" == "1" ]] || continue

  if [[ "$server_id" == "$SELF_ID" ]]; then
    echo "[skip] self: $server_id"
    continue
  fi

  target_host="$ssh_host"
  if [[ -n "$SSH_USER" && "$target_host" != *@* ]]; then
    target_host="$SSH_USER@$target_host"
  fi

  target_repo="${repo_path:-~/dotfiles}"
  target_port="${ssh_port:-$SSH_PORT_DEFAULT}"

  ssh_cmd=(ssh)
  [[ -n "$target_port" ]] && ssh_cmd+=(-p "$target_port")
  [[ -n "$SSH_IDENTITY" ]] && ssh_cmd+=(-i "$SSH_IDENTITY")

  echo "[run] $server_id ($target_host)"

  if "${ssh_cmd[@]}" "$target_host" "DOTFILES_TARGET_REPO=$(printf %q "$target_repo") DOTFILES_CLONE_URL=$(printf %q "$CLONE_URL") bash -s" <<'REMOTE'
set -euo pipefail

if [[ "$DOTFILES_TARGET_REPO" == "~" ]]; then
  DOTFILES_TARGET_REPO="$HOME"
elif [[ "$DOTFILES_TARGET_REPO" == "~/"* ]]; then
  DOTFILES_TARGET_REPO="$HOME/${DOTFILES_TARGET_REPO#~/}"
fi

if ! git -C "$DOTFILES_TARGET_REPO" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  mkdir -p "$(dirname "$DOTFILES_TARGET_REPO")"
  git clone --origin origin "$DOTFILES_CLONE_URL" "$DOTFILES_TARGET_REPO"
fi

cd "$DOTFILES_TARGET_REPO"
git pull --ff-only origin main
./install.sh -y
systemctl --user daemon-reload
systemctl --user restart dotfiles-auto-update.timer
REMOTE
  then
    echo "[ok] $server_id"
  else
    echo "[error] $server_id" >&2
    fail=1
  fi
done < "$INVENTORY"

if [[ "$fail" -ne 0 ]]; then
  echo "[done] rollout finished with failures" >&2
  exit 1
fi

echo "[done] rollout finished successfully"
```

## Post-check

Run this after rollout:

```bash
DOTFILES_SYNC_CONTROLLER=true ~/.local/bin/dotfiles-sync run --repo ~/dotfiles --dry-run
```
