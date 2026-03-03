# Dotfiles

Personal shell/dev environment dotfiles with a modular 6-phase installer.

## What Is Included

- `zsh`: oh-my-zsh + powerlevel10k + shared aliases + lazy nvm loading
- `bash`: oh-my-bash + shared aliases + lazy nvm loading
- `tmux`: oh-my-tmux local configuration
- `git`: template `.gitconfig` with practical defaults
- `claude/`: Claude Code setup (`CLAUDE.md`, `ML-STACK.md`, `rules/`, `settings.json`)
- `opencode/`: OpenCode setup (`opencode.json`, `oh-my-opencode.json`)
- `install/`: reusable installer modules and phase orchestration

## Quick Start

```bash
git clone https://github.com/jaehyun-ko/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

Supported OS detection: Ubuntu/Debian, RedHat/CentOS/Fedora, Arch, macOS.

## Installer Phases

1. System preparation
2. Core package installation
3. Shell environment setup
4. Development tools installation
5. System tools installation
6. Final configuration (symlinks, optional Claude config, OpenCode config, Codex/OmO sync, dotfiles auto-update, default shell)

## Managed Dotfiles

The installer symlinks these files to `$HOME`:

- `.zshrc`
- `.bashrc`
- `.tmux.conf.local`
- `.p10k.zsh`
- `aliases.sh`
- `.gitconfig`

## Codex/OmO Sync Stack

During install, it sets up:

- `codex-sync`, `omo-sync`, `dotfiles-sync`, `opencode-config-sync`, `opencode` launchers in `~/.local/bin/`
- `agentic-skill-updater.timer` (user systemd, hourly)
- Codex CLI / OpenCode CLI / oh-my-opencode install attempts
- Symlinked OpenCode config files from repo to `~/.config/opencode/`

Behavior:

- Runs `agentic-researcher` skill sync before launching `codex`/`oh-my-opencode`
- Runs `opencode-config-sync` before launching `oh-my-opencode` (preserves user-edited config files; use `--force` to relink)
- Skips frequent checks when within interval (default 15 min)

Environment variables:

- `AGENTIC_RESEARCHER_REPO` (default: `~/projects/agentic-researcher`)
- `SKILL_SYNC_MIN_CHECK_INTERVAL_MINUTES` (default: `15`)
- `SKILL_SYNC_NO_PULL=1` (skip `git pull` in launch-time sync)
- `SKILL_SYNC_CHANNEL` (`stable`/`canary`)
- `SKILL_SYNC_CANARY_PERCENT`
- `SKILL_SYNC_INSTALL_ROOT`
- `SKILL_SYNC_SKILL_NAME`

## Dotfiles Auto-Update

During install, it also sets up:

- `dotfiles-auto-update.timer` (user systemd, every 15 minutes)
- `dotfiles-auto-update.service` using `bin/dotfiles-sync`

Behavior:

- Uses `dotfiles-sync run` (subcommand CLI)
- Legacy flag-only interface (`dotfiles-sync --servers ...`) is removed
- Local sync is enforced with `fetch + reset --hard + clean + pull --ff-only`
- Server-specific overlays are applied from `overlays/<server_id>/...` using `rsync --delete`
- Runs `opencode-config-sync --force` after sync (host-aware source selection)
- If `DOTFILES_SYNC_CONTROLLER=true`, it also fan-outs to other servers from `sync/servers.tsv`
- Fan-out retries failed targets (`DOTFILES_SYNC_RETRY_MAX`, default `3`) and returns non-zero if any target fails

Environment variables:

- `DOTFILES_AUTO_UPDATE_REMOTE` (default: `origin`)
- `DOTFILES_AUTO_UPDATE_BRANCH` (default: `main`)
- `DOTFILES_SYNC_CONTROLLER` (default: `false`)
- `DOTFILES_SYNC_SSH_USER`, `DOTFILES_SYNC_SSH_PORT`, `DOTFILES_SYNC_SSH_IDENTITY` (keep in local env file, not in git)
- `DOTFILES_SERVER_ID` (optional; fallback: `hostname -s`)
- `DOTFILES_SYNC_POST_CMD` (default: `~/.local/bin/opencode-config-sync --force`)

Recommended setup for multi-server:

1. Clone this repo on each server to the same path (for example `~/dotfiles`).
2. Run `./install.sh -y` once per server.
3. Configure `sync/servers.tsv` and `sync/overlay-allowlist.txt` in the repo.
4. Set `DOTFILES_SYNC_CONTROLLER=true` on exactly one control node.
5. Let each server's `dotfiles-auto-update.timer` run; the controller will also fan-out.

Example:

```bash
export DOTFILES_AUTO_UPDATE_REMOTE="origin"
export DOTFILES_AUTO_UPDATE_BRANCH="main"
export DOTFILES_SYNC_CONTROLLER="true"
./install.sh
```

Optional local-only secrets (`~/.config/dotfiles-sync/config.env`):

```bash
DOTFILES_SYNC_SSH_USER=ubuntu
DOTFILES_SYNC_SSH_IDENTITY=~/.ssh/id_ed25519
DOTFILES_SYNC_SSH_PORT=22
```

Inventory format (`sync/servers.tsv`):

```tsv
server_id	ssh_host	repo_path	ssh_port	post_cmd	enabled
gpu-1	gpu-1.example.com	~/dotfiles	22		1
gpu-2	gpu-2.example.com	~/dotfiles	22		1
```

Manual commands:

```bash
dotfiles-sync validate --repo ~/dotfiles
dotfiles-sync local --repo ~/dotfiles
dotfiles-sync fanout --repo ~/dotfiles
dotfiles-sync run --repo ~/dotfiles
```

## Post-Install

```bash
source ~/.zshrc
# Optional prompt setup refresh
p10k configure
```

Update identity placeholders in `~/.gitconfig`:

```bash
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

## Customization

1. Edit shared aliases in `aliases.sh`.
2. Edit package/tool URL lists in `install/config.sh`.
3. Adjust shell plugins directly in `.zshrc` or `.bashrc`.
4. Customize Claude Code rules under `claude/rules/`.

## Troubleshooting

- Default shell: `chsh -s "$(which zsh)"`
- Prompt font rendering: install a Nerd Font
- Installer permissions: `chmod +x install.sh`
- Skip Codex/OmO sync stack: `./install.sh --skip-codex-sync`
- Skip dotfiles auto-update timer: `./install.sh --skip-dotfiles-autoupdate`
