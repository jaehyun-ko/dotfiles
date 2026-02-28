# Dotfiles

개인 설정 파일 및 자동 설치 스크립트

## 설치

```bash
git clone https://github.com/jaehyun-ko/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh
```

OS 자동 감지 (Ubuntu/Debian, RedHat/CentOS, Arch, macOS)

## 포함 항목

| 설정 | 프레임워크 |
|------|-----------|
| zsh | oh-my-zsh + powerlevel10k |
| bash | oh-my-bash |
| tmux | oh-my-tmux |
| git | gitconfig |

**자동 설치:** zsh, bash, tmux, git, nvm, autojump, cargo/rust, curl, wget

## Codex/OMX Sync Stack (선택)

설치 중 선택하면 아래가 함께 설정됩니다.

- `codex-sync`, `omx-sync` 런처 (`~/.local/bin/`)
- `agentic-skill-updater.timer` (user systemd, 1시간 주기)
- Codex CLI / oh-my-codex 자동 설치 시도

기본 동작:

- 실행 시 `agentic-researcher` 스킬 동기화 체크 후 `codex`/`omx` 실행
- 최근 체크가 너무 최근이면 자동 스킵 (기본 15분)

환경변수:

- `AGENTIC_RESEARCHER_REPO` (기본: `~/projects/agentic-researcher`)
- `SKILL_SYNC_MIN_CHECK_INTERVAL_MINUTES` (기본: `15`)
- `SKILL_SYNC_NO_PULL=1` (실행 시 `git pull` 생략)
- `SKILL_SYNC_CHANNEL` (`stable`/`canary`)
- `SKILL_SYNC_CANARY_PERCENT`
- `SKILL_SYNC_INSTALL_ROOT`
- `SKILL_SYNC_SKILL_NAME`

## 설치 후

```bash
source ~/.zshrc  # 또는 터미널 재시작
p10k configure   # powerlevel10k 재설정 (선택)
```

## 문제 해결

- **기본 셸 변경:** `chsh -s $(which zsh)`
- **폰트 깨짐:** [Nerd Fonts](https://www.nerdfonts.com/) 설치
- **권한 오류:** `chmod +x install.sh`
- **Codex/OMX sync만 건너뛰기:** `./install.sh --skip-codex-sync`
