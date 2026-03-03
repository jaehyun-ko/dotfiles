#!/usr/bin/env bash

# Shared helper functions for dotfiles launchers.
# - Keep this file bash-only (no external deps required).
# - Do NOT set -e/-u here; callers decide their safety flags.

df_path_prepend() {
  local dir="$1"
  [[ -n "$dir" && -d "$dir" ]] || return 0
  case ":${PATH:-}:" in
    *":$dir:"*) ;;
    *) PATH="$dir:${PATH:-}" ;;
  esac
  export PATH
}

df_can_sort_version() {
  command -v sort >/dev/null 2>&1 || return 1
  sort -V </dev/null >/dev/null 2>&1
}

df_realpath() {
  local path="$1"

  if command -v realpath >/dev/null 2>&1; then
    realpath "$path"
    return 0
  fi

  if command -v python3 >/dev/null 2>&1; then
    python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$path"
    return 0
  fi

  # Fallback: best-effort (may still contain symlinks).
  if [[ "$path" == /* ]]; then
    printf '%s\n' "$path"
  else
    printf '%s\n' "$(pwd)/$path"
  fi
}

df_find_nvm_cmd_path() {
  local cmd="$1"
  local nvm_dir="${NVM_DIR:-$HOME/.nvm}"

  [[ -d "$nvm_dir/versions/node" ]] || return 1

  local _nullglob_set="0"
  shopt -q nullglob && _nullglob_set="1"
  shopt -s nullglob

  local matches=("$nvm_dir"/versions/node/*/bin/"$cmd")

  [[ "$_nullglob_set" == "1" ]] || shopt -u nullglob

  ((${#matches[@]} > 0)) || return 1

  local best=""
  if df_can_sort_version; then
    best="$(printf '%s\n' "${matches[@]}" | sort -V | tail -n 1)"
  else
    best="$(printf '%s\n' "${matches[@]}" | sort | tail -n 1)"
  fi

  [[ -n "$best" && -x "$best" ]] || return 1
  printf '%s\n' "$best"
}

df_exec_node_global_cmd() {
  local cmd="$1"
  local self_real="$2"
  shift 2

  local cmd_path=""
  if cmd_path="$(df_find_nvm_cmd_path "$cmd" 2>/dev/null)"; then
    df_path_prepend "$(dirname "$cmd_path")"
    exec "$cmd_path" "$@"
  fi

  if command -v which >/dev/null 2>&1; then
    local candidate candidate_real
    while IFS= read -r candidate; do
      [[ -n "$candidate" ]] || continue
      candidate_real="$(df_realpath "$candidate" 2>/dev/null || echo "$candidate")"
      [[ "$candidate_real" == "$self_real" ]] && continue
      [[ -x "$candidate" ]] || continue
      exec "$candidate" "$@"
    done < <(which -a "$cmd" 2>/dev/null || true)
  fi

  echo "$cmd: command not found (install via npm or run install.sh)" >&2
  return 127
}

