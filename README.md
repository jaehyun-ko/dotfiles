# Dotfiles

이 저장소는 개인 설정 파일들과 지능형 설치 스크립트를 포함하고 있습니다.

## 포함된 설정 파일들

- `.zshrc` - Zsh 설정 (Oh My Zsh, Powerlevel10k 테마)
- `.bashrc` - Bash 설정 (Oh My Bash)
- `.gitconfig` - Git 설정
- `.tmux.conf.local` - Tmux 설정 (Oh My Tmux)
- `.p10k.zsh` - Powerlevel10k 테마 설정

## 자동 설치 프로그램 목록

설치 스크립트는 다음 프로그램들을 자동으로 설치합니다:

- **zsh** - Z shell
- **oh-my-zsh** - Zsh 프레임워크
- **powerlevel10k** - Zsh 테마
- **zsh-autosuggestions** - 명령어 자동 완성 플러그인
- **zsh-syntax-highlighting** - 문법 강조 플러그인
- **autojump** - 디렉토리 빠른 이동
- **nvm** - Node.js 버전 관리자
- **git** - 버전 관리 시스템
- **tmux** - 터미널 멀티플렉서
- **oh-my-tmux** - Tmux 설정 프레임워크
- **bash** - Bash shell
- **oh-my-bash** - Bash 프레임워크
- **cargo/rust** - Rust 프로그래밍 언어 및 패키지 매니저
- **curl, wget** - HTTP 다운로드 도구

## 설치 방법

### 1. 저장소 클론

```bash
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/dotfiles
cd ~/dotfiles
```

### 2. 설치 스크립트 실행

```bash
./install.sh
```

설치 스크립트는 다음을 수행합니다:
- OS를 자동으로 감지 (Ubuntu/Debian, RedHat/CentOS, Arch, macOS 지원)
- 필요한 패키지들을 설치
- 기존 설정 파일들을 백업 (.backup 확장자로)
- dotfiles를 홈 디렉토리에 심볼릭 링크로 연결

### 3. 터미널 재시작

설치가 완료되면 터미널을 재시작하거나 다음 명령을 실행하세요:

```bash
source ~/.zshrc
```

### 4. Powerlevel10k 설정 (선택사항)

처음 설치 시 Powerlevel10k 설정 마법사가 자동으로 실행됩니다. 
수동으로 재설정하려면:

```bash
p10k configure
```

## 수동 설치

특정 구성 요소만 설치하고 싶다면:

### Oh My Zsh
```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

### Powerlevel10k
```bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ~/powerlevel10k
```

### NVM
```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
```

## 문제 해결

### Zsh를 기본 셸로 설정
```bash
chsh -s $(which zsh)
```

### 폰트 문제
Powerlevel10k가 제대로 표시되지 않는다면 [Nerd Fonts](https://www.nerdfonts.com/)를 설치하세요.

### 권한 문제
설치 스크립트 실행 시 권한 오류가 발생하면:
```bash
chmod +x install.sh
```

## 사용자 정의

### 새로운 별칭 추가
`.zshrc` 또는 `.bashrc` 파일에 별칭을 추가하세요:
```bash
alias ll='ls -la'
alias gs='git status'
```

### 플러그인 추가
`.zshrc`의 `plugins` 배열에 새로운 플러그인을 추가하세요:
```bash
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    autojump
    # 새로운 플러그인 추가
)
```

## 백업

기존 설정 파일들은 `.backup` 확장자로 자동 백업됩니다:
- `.zshrc` → `.zshrc.backup`
- `.bashrc` → `.bashrc.backup`
- 등등...

## 라이센스

이 dotfiles는 개인 사용을 위한 것입니다. 자유롭게 수정하여 사용하세요.