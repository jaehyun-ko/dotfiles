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

## 설치 후

```bash
source ~/.zshrc  # 또는 터미널 재시작
p10k configure   # powerlevel10k 재설정 (선택)
```

## 문제 해결

- **기본 셸 변경:** `chsh -s $(which zsh)`
- **폰트 깨짐:** [Nerd Fonts](https://www.nerdfonts.com/) 설치
- **권한 오류:** `chmod +x install.sh`
