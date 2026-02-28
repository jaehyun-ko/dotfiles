# Dotfiles

Personal shell/dev environment dotfiles with a modular 6-phase installer.

## What Is Included

- `zsh`: oh-my-zsh + powerlevel10k + shared aliases + lazy nvm loading
- `bash`: oh-my-bash + shared aliases + lazy nvm loading
- `tmux`: oh-my-tmux local configuration
- `git`: template `.gitconfig` with practical defaults
- `claude/`: Claude Code setup (`CLAUDE.md`, `ML-STACK.md`, `rules/`, `settings.json`)
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
6. Final configuration (symlinks, optional Claude config, optional Codex/OMX sync stack, default shell)

## Managed Dotfiles

The installer symlinks these files to `$HOME`:

- `.zshrc`
- `.bashrc`
- `.tmux.conf.local`
- `.p10k.zsh`
- `aliases.sh`
- `.gitconfig`

## Codex/OMX Sync Stack (Optional)

If enabled during install, it sets up:

- `codex-sync`, `omx-sync` launchers in `~/.local/bin/`
- `agentic-skill-updater.timer` (user systemd, hourly)
- Codex CLI / oh-my-codex install attempts

Behavior:

- Runs `agentic-researcher` skill sync before launching `codex`/`omx`
- Skips frequent checks when within interval (default 15 min)

Environment variables:

- `AGENTIC_RESEARCHER_REPO` (default: `~/projects/agentic-researcher`)
- `SKILL_SYNC_MIN_CHECK_INTERVAL_MINUTES` (default: `15`)
- `SKILL_SYNC_NO_PULL=1` (skip `git pull` in launch-time sync)
- `SKILL_SYNC_CHANNEL` (`stable`/`canary`)
- `SKILL_SYNC_CANARY_PERCENT`
- `SKILL_SYNC_INSTALL_ROOT`
- `SKILL_SYNC_SKILL_NAME`

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
- Skip Codex/OMX sync stack: `./install.sh --skip-codex-sync`
