# Dotfiles

Personal shell/dev environment dotfiles with a modular 6-phase installer.

## What Is Included

- `zsh`: oh-my-zsh + powerlevel10k + shared aliases + lazy nvm loading
- `bash`: oh-my-bash + shared aliases + lazy nvm loading
- `tmux`: oh-my-tmux local configuration
- `git`: template `.gitconfig` with practical defaults
- `install/`: reusable installer modules and phase orchestration
- `bin/`: dotfiles repository sync helpers
- `systemd/`: optional user-level dotfiles auto-update timer

This repo does not manage Claude, OpenCode/oh-my-opencode, Codex, or oh-my-codex settings. Install and configure those tools directly.

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
6. Final configuration: symlinks, dotfiles helpers, dotfiles auto-update, default shell

## Managed Dotfiles

The installer symlinks these files to `$HOME`:

- `.zshrc`
- `.bashrc`
- `.tmux.conf.local`
- `.p10k.zsh`
- `aliases.sh`
- `.gitconfig`

## Dotfiles Helpers

During install, the repo links these helpers into `~/.local/bin`:

- `dotfiles-sync`
- `dotfiles-deploy`
- `dotfiles-register`
- `dotfiles-chatbot-install`
- `dotfiles-post-sync`
- `dotfiles-bin-sync`
- `dotfiles-systemd-sync`

`dotfiles-bin-sync` also removes stale repo-managed chatbot launcher symlinks if they still point at this checkout.

## Chatbot CLIs

The repo installs only native CLI binaries, not their settings:

- `claude` from `@anthropic-ai/claude-code`
- `codex` from `@openai/codex`
- `opencode` from `opencode-ai`

This runs during `install.sh` and `dotfiles-post-sync`. Disable it with:

```bash
export DOTFILES_INSTALL_CHATBOT_CLIS=false
```

## Server Registry

Servers self-register during `install.sh` by writing `sync/registry/<server_id>.env` and pushing it to `origin/main`. `dotfiles-deploy` reads this registry for fan-out. This replaces manual TSV editing for normal use.

Set these on a server before `install.sh` if auto-detection is not enough:

```bash
export DOTFILES_SERVER_ID="gpu-1"
export DOTFILES_SYNC_SSH_HOST="gpu-1.example.com"
export DOTFILES_SYNC_SSH_PORT=22
```

If the server has read-only Git credentials, registration will warn and continue; you can run `dotfiles-register --no-push` and commit the generated file from a machine with push access.

Disable self-registration with:

```bash
./install.sh --skip-node-register
```

## Dotfiles Auto-Update

Auto-update timers are disabled by default. The preferred rollout path is push-based:

```bash
git commit -am "Update dotfiles"
dotfiles-deploy
```

`dotfiles-deploy` pushes the current commit, runs local post-sync, then fans out to enabled servers from `sync/registry/`. If the registry is empty, `sync/servers.tsv` is still supported as a legacy fallback.

If explicitly enabled with `./install.sh --enable-dotfiles-autoupdate`, the installer sets up:

- `dotfiles-auto-update.timer` (user systemd, every 15 minutes)
- `dotfiles-auto-update.service` using `bin/dotfiles-sync`

Behavior:

- Timer mode uses `dotfiles-sync run`.
- Local sync is enforced with `fetch + reset --hard + clean + pull --ff-only`.
- Submodules are synced only when `.gitmodules` exists.
- Server-specific overlays are applied from `overlays/<server_id>/...` using `rsync --delete`.
- Runs `dotfiles-post-sync` after sync:
  - `dotfiles-bin-sync`
  - legacy Claude/OpenCode config symlink cleanup, only when the symlink points at this checkout
  - `dotfiles-systemd-sync`
- If `DOTFILES_SYNC_CONTROLLER=true`, it also fan-outs to other servers from `sync/servers.tsv`.
- Fan-out retries failed targets (`DOTFILES_SYNC_RETRY_MAX`, default `3`) and returns non-zero if any target fails.

Environment variables:

- `DOTFILES_AUTO_UPDATE_REMOTE` (default: `origin`)
- `DOTFILES_AUTO_UPDATE_BRANCH` (default: `main`)
- `DOTFILES_SYNC_CONTROLLER` (default: `false`)
- `DOTFILES_SYNC_SSH_USER`, `DOTFILES_SYNC_SSH_PORT`, `DOTFILES_SYNC_SSH_IDENTITY` (keep in local env file, not in git)
- `DOTFILES_SERVER_ID` (optional; fallback: `hostname -s`)
- `DOTFILES_SYNC_POST_CMD` (optional override; default: `"<repo>/bin/dotfiles-post-sync"`)
- `DOTFILES_AUTO_UPDATE_ENABLED=true` (runtime opt-in for `dotfiles-systemd-sync`)

Recommended setup for multi-server:

1. Clone this repo on each server to the same path, for example `~/dotfiles`.
2. Run `./install.sh -y` once per server.
3. Run `./install.sh -y` on each server once so it registers itself.
4. Set `DOTFILES_SYNC_CONTROLLER=true` on exactly one control node.
5. Use `dotfiles-deploy` from the controller after committing changes.

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

Legacy inventory format (`sync/servers.tsv`):

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
dotfiles-deploy
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
4. Configure chatbot tools in their own native config locations.

## Troubleshooting

- Default shell: `chsh -s "$(which zsh)"`
- Prompt font rendering: install a Nerd Font
- Installer permissions: `chmod +x install.sh`
- Skip chatbot CLI installation: `./install.sh --skip-chatbot-clis`
- Skip node registry: `./install.sh --skip-node-register`
- Enable dotfiles auto-update timer: `./install.sh --enable-dotfiles-autoupdate`
