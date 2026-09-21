#!/usr/bin/env bash
set -e

# ==============================================================================
# Ezlmt's Automated Dotfiles & Development Environment Bootstrap
# Supports macOS, Ubuntu/Debian, Arch Linux, and Fedora
# ==============================================================================

# Color output helpers
BOLD='\033[1m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info()    { echo -e "${BLUE}${BOLD}==>${NC} ${BOLD}$*${NC}"; }
success() { echo -e "${GREEN}${BOLD}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}${BOLD}[WARN]${NC} $*"; }
error()   { echo -e "${RED}${BOLD}[ERROR]${NC} $*"; }

GITHUB_USER="Ezlmt"
TARGET_DIR="${HOME}/.dotfiles"

# If script was piped through curl/wget, clone dotfiles first
if [ ! -f "${BASH_SOURCE[0]}" ] || [ ! -d "$(dirname "${BASH_SOURCE[0]}")/.git" ]; then
  info "Bootstrapping dotfiles repository into ${TARGET_DIR}..."
  if [ -d "${TARGET_DIR}/.git" ]; then
    git -C "${TARGET_DIR}" pull --ff-only || true
  else
    git clone "https://github.com/${GITHUB_USER}/dotfiles.git" "${TARGET_DIR}"
  fi
  exec bash "${TARGET_DIR}/install.sh" "$@"
fi

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "${HOME}/.local/bin" "${HOME}/.config" "${HOME}/go/bin"

# Profile and execution options
PROFILE=""
INTERACTIVE=true

is_termux() {
  [ -n "${TERMUX_VERSION:-}" ] || [ -d "/data/data/com.termux/files/usr" ]
}

detect_recommended_profile() {
  if [ -d "/google" ] || [[ "$(hostname 2>/dev/null)" == *".googlers.com"* ]]; then
    echo "android-hal"
  else
    echo "core"
  fi
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -p|--profile)
        PROFILE="$2"
        shift 2
        ;;
      --core)
        PROFILE="core"
        shift
        ;;
      -y|--yes|--non-interactive)
        INTERACTIVE=false
        shift
        ;;
      -h|--help)
        echo -e "${BOLD}Ezlmt Dotfiles Bootstrap Installer${NC}"
        echo
        echo "Usage: ./install.sh [options]"
        echo
        echo "Options:"
        echo "  -p, --profile <name>   Select profile ('core', 'android-hal')"
        echo "  --core                 Install universal base profile ('core')"
        echo "  -y, --non-interactive  Run without interactive prompts"
        echo "  -h, --help             Show this help message"
        exit 0
        ;;
      *)
        warn "Unknown option: $1 (ignoring)"
        shift
        ;;
    esac
  done
}

resolve_profile() {
  local recommended
  recommended="$(detect_recommended_profile)"

  if [ -z "$PROFILE" ]; then
    if is_termux; then
      PROFILE="core"
    elif [ "$INTERACTIVE" = true ] && [ -t 0 ]; then
      echo
      info "Please select your development environment profile:"
      echo "  1) core        - Universal base configuration (Personal / Linux / macOS)"
      echo "  2) android-hal - Google Pixel Camera & Lyric HAL development"
      echo
      if [ "$recommended" = "android-hal" ]; then
        echo -e "  ${YELLOW}* Detected Google workstation environment (Recommended: android-hal)${NC}"
        read -r -p "Select profile [1/2] (Default: 2 [android-hal]): " choice
        case "$choice" in
          1) PROFILE="core" ;;
          2|"") PROFILE="android-hal" ;;
          *) PROFILE="$choice" ;;
        esac
      else
        read -r -p "Select profile [1/2] (Default: 1 [core]): " choice
        case "$choice" in
          1|"") PROFILE="core" ;;
          2) PROFILE="android-hal" ;;
          *) PROFILE="$choice" ;;
        esac
      fi
    else
      PROFILE="$recommended"
    fi
  fi
}

checkout_dotfiles_branch() {
  local target_branch="core"
  if [ "$PROFILE" = "android-hal" ]; then
    target_branch="profile/android-hal"
  elif [ "$PROFILE" != "core" ] && [ -n "$PROFILE" ]; then
    target_branch="profile/${PROFILE}"
  fi

  info "Switching dotfiles repository to branch: ${BOLD}${target_branch}${NC}..."
  if git -C "${DOTFILES_DIR}" show-ref --verify --quiet "refs/heads/${target_branch}"; then
    git -C "${DOTFILES_DIR}" checkout "${target_branch}" 2>/dev/null || true
  elif git -C "${DOTFILES_DIR}" show-ref --verify --quiet "refs/remotes/origin/${target_branch}"; then
    git -C "${DOTFILES_DIR}" checkout -b "${target_branch}" "origin/${target_branch}" 2>/dev/null || true
  else
    warn "Branch '${target_branch}' not found in dotfiles; keeping current branch ($(git -C "${DOTFILES_DIR}" branch --show-current 2>/dev/null || echo 'current'))."
  fi
}

echo -e "${BLUE}${BOLD}"
cat << "BANNER"
  ______     _             _     ____        _    __ _ _           
 |  ____|   | |           | |   |  _ \      | |  / _(_) |          
 | |__   ___| |_ __ ___   | |_  | | | | ___ | |_| |_ _| | ___  ___ 
 |  __| |_  / | '_ ` _ \  | __| | | | |/ _ \| __|  _| | |/ _ \/ __|
 | |____ / /| | | | | | | | |_  | |_| | (_) | |_| | | | |  __/\__ \
 |______/___|_|_| |_| |_|  \__| |____/ \___/ \__|_| |_|_|\___||___/
BANNER
echo -e "         Personal Development Environment Bootstrap"
echo -e "==============================================================${NC}"

# ------------------------------------------------------------------------------
# 1. Package Management & Core Tools
# ------------------------------------------------------------------------------
install_packages() {
  info "Checking and installing required system packages..."
  OS="$(uname -s)"
  ARCH="$(uname -m)"

  if is_termux; then
    info "Termux (Android) detected! Installing native packages via pkg..."
    pkg update -y || true
    pkg install -y git curl zsh tmux neovim ripgrep fd fzf zoxide lazygit yazi \
      unzip clang make lua-language-server openssh || true

    # Ensure no foreign Linux glibc binaries in ~/.local/bin shadow Termux's native $PREFIX/bin binaries
    rm -f "${HOME}/.local/bin/nvim" "${HOME}/.local/bin/lazygit" \
          "${HOME}/.local/bin/yazi" "${HOME}/.local/bin/ya" "${HOME}/.local/bin/zoxide" 2>/dev/null || true

    success "Termux native packages installed."
    return 0
  fi

  case "$OS" in
    Darwin)
      if ! command -v brew >/dev/null 2>&1; then
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv 2>/dev/null)"
      fi
      info "Installing packages via Homebrew..."
      brew install git curl zsh tmux neovim ripgrep fd fzf zoxide lazygit yazi
      ;;

    Linux)
      if command -v apt-get >/dev/null 2>&1; then
        info "Debian/Ubuntu detected, updating apt..."
        sudo apt-get update -y || true
        sudo apt-get install -y git curl zsh tmux ripgrep fd-find fzf build-essential unzip || true
        sudo apt-get install -y zoxide lazygit || true

        # Symlink fd -> fdfind
        if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
          ln -sf "$(command -v fdfind)" "${HOME}/.local/bin/fd"
        fi

      elif command -v pacman >/dev/null 2>&1; then
        info "Arch Linux detected..."
        sudo pacman -S --needed --noconfirm git curl zsh tmux neovim ripgrep fd fzf zoxide lazygit yazi base-devel unzip || true

      elif command -v dnf >/dev/null 2>&1; then
        info "Fedora detected..."
        sudo dnf install -y git curl zsh tmux neovim ripgrep fd-find fzf zoxide lazygit unzip || true
        if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
          ln -sf "$(command -v fdfind)" "${HOME}/.local/bin/fd"
        fi
      fi

      # Ensure zoxide is installed
      if ! command -v zoxide >/dev/null 2>&1; then
        info "Installing zoxide via official installer..."
        curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh || true
      fi

      # Ensure modern Neovim (>= 0.10)
      NEED_NVIM=false
      if ! command -v nvim >/dev/null 2>&1; then
        NEED_NVIM=true
      else
        NVIM_VER_STR="$(nvim --version 2>/dev/null | head -n 1 | grep -oE '[0-9]+\.[0-9]+' | head -n 1 || true)"
        if [ -z "$NVIM_VER_STR" ]; then
          NEED_NVIM=true
        else
          NVIM_MAJOR="${NVIM_VER_STR%%.*}"
          NVIM_MINOR="${NVIM_VER_STR##*.}"
          if [ "${NVIM_MAJOR:-0}" -lt 1 ] && [ "${NVIM_MINOR:-0}" -lt 10 ]; then
            NEED_NVIM=true
          fi
        fi
      fi

      if [ "$NEED_NVIM" = true ]; then
        info "Installing latest Neovim binary from GitHub releases..."
        NVIM_ARCH="$ARCH"
        [ "$ARCH" = "aarch64" ] && NVIM_ARCH="arm64"
        NVIM_TAR="nvim-linux-${NVIM_ARCH}.tar.gz"
        curl -fsSL -o "/tmp/${NVIM_TAR}" "https://github.com/neovim/neovim/releases/latest/download/${NVIM_TAR}" || true
        if [ -f "/tmp/${NVIM_TAR}" ]; then
          mkdir -p "${HOME}/.local/nvim" "${HOME}/.local/bin"
          tar -xzf "/tmp/${NVIM_TAR}" -C "${HOME}/.local/nvim" --strip-components=1
          ln -sf "${HOME}/.local/nvim/bin/nvim" "${HOME}/.local/bin/nvim"
          sudo ln -sf "${HOME}/.local/bin/nvim" /usr/local/bin/nvim 2>/dev/null || true
          rm -f "/tmp/${NVIM_TAR}"
          export PATH="${HOME}/.local/bin:${PATH}"
          success "Neovim installed to ${HOME}/.local/bin/nvim"
        else
          error "Failed to download Neovim binary."
        fi
      fi

      # Ensure lazygit is installed
      if ! command -v lazygit >/dev/null 2>&1; then
        info "Installing lazygit..."
        LG_VER="$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')"
        if [ -n "$LG_VER" ]; then
          curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LG_VER}_Linux_x86_64.tar.gz"
          tar -xzf /tmp/lazygit.tar.gz -C "${HOME}/.local/bin" lazygit
          chmod +x "${HOME}/.local/bin/lazygit"
          rm -f /tmp/lazygit.tar.gz
        fi
      fi

      # Ensure Yazi is installed
      if ! command -v yazi >/dev/null 2>&1; then
        info "Installing latest Yazi prebuilt release..."
        YAZI_ZIP="yazi-${ARCH}-unknown-linux-musl.zip"
        curl -fsSL -o "/tmp/${YAZI_ZIP}" "https://github.com/sxyazi/yazi/releases/latest/download/${YAZI_ZIP}" || true
        if [ -f "/tmp/${YAZI_ZIP}" ]; then
          unzip -q -o "/tmp/${YAZI_ZIP}" -d /tmp/yazi_extracted
          cp -f /tmp/yazi_extracted/*/yazi "${HOME}/.local/bin/"
          cp -f /tmp/yazi_extracted/*/ya "${HOME}/.local/bin/"
          rm -rf "/tmp/${YAZI_ZIP}" /tmp/yazi_extracted
        fi
      fi
  esac
  # Ensure ~/.local/bin is in PATH for non-zsh shells too
  for pf in "${HOME}/.bashrc" "${HOME}/.profile"; do
    if [ -f "$pf" ] && ! grep -q '\.local/bin' "$pf" 2>/dev/null; then
      echo 'export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"' >> "$pf"
    fi
  done
  success "Base packages installed."
}

# ------------------------------------------------------------------------------
# 2. Setup Oh My Zsh, Powerlevel10k & Zsh Plugins
# ------------------------------------------------------------------------------
setup_zsh() {
  info "Setting up Oh My Zsh and plugins..."
  ZSH_DIR="${HOME}/.oh-my-zsh"

  if [ ! -d "${ZSH_DIR}" ]; then
    info "Installing Oh My Zsh..."
    RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  fi

  ZSH_CUSTOM="${ZSH_DIR}/custom"

  # Powerlevel10k theme
  if [ ! -d "${ZSH_CUSTOM}/themes/powerlevel10k" ]; then
    info "Cloning Powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM}/themes/powerlevel10k"
  else
    git -C "${ZSH_CUSTOM}/themes/powerlevel10k" pull --ff-only || true
  fi

  # zsh-autosuggestions
  if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" ]; then
    info "Cloning zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM}/plugins/zsh-autosuggestions"
  else
    git -C "${ZSH_CUSTOM}/plugins/zsh-autosuggestions" pull --ff-only || true
  fi

  # zsh-syntax-highlighting
  if [ ! -d "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" ]; then
    info "Cloning zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting"
  else
    git -C "${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting" pull --ff-only || true
  fi

  success "Oh My Zsh & plugins ready."
}

# ------------------------------------------------------------------------------
# 3. Link Dotfiles (~/.zshrc, ~/.p10k.zsh, bin tools)
# ------------------------------------------------------------------------------
link_dotfiles() {
  info "Linking shell configurations and bin tools..."

  backup_and_link() {
    local src="$1"
    local dest="$2"
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
      warn "Backing up existing $dest to ${dest}.bak"
      mv "$dest" "${dest}.bak"
    fi
    mkdir -p "$(dirname "$dest")"
    ln -sf "$src" "$dest"
    success "Linked $dest -> $src"
  }

  mkdir -p "${DOTFILES_DIR}/profiles" "${HOME}/.local/bin"

  backup_and_link "${DOTFILES_DIR}/.zshrc" "${HOME}/.zshrc"
  backup_and_link "${DOTFILES_DIR}/.p10k.zsh" "${HOME}/.p10k.zsh"
  if [ -f "${DOTFILES_DIR}/.gitconfig" ]; then
    backup_and_link "${DOTFILES_DIR}/.gitconfig" "${HOME}/.gitconfig"
  fi

  # Auto-link all executable scripts in bin/ to ~/.local/bin
  if [ -d "${DOTFILES_DIR}/bin" ]; then
    info "Linking helper tools from ${DOTFILES_DIR}/bin to ${HOME}/.local/bin..."
    for tool in "${DOTFILES_DIR}/bin"/*; do
      if [ -f "$tool" ]; then
        chmod +x "$tool" 2>/dev/null || true
        backup_and_link "$tool" "${HOME}/.local/bin/$(basename "$tool")"
      fi
    done
  fi
}

# ------------------------------------------------------------------------------
# 4. Setup Neovim (Ezlmt/nvim)
# ------------------------------------------------------------------------------
setup_nvim() {
  info "Setting up Neovim configuration (Ezlmt/nvim)..."
  NVIM_CONFIG_DIR="${HOME}/.config/nvim"

  local target_branch="core"
  if [ "$PROFILE" = "android-hal" ]; then
    target_branch="profile/android-hal"
  elif [ "$PROFILE" != "core" ] && [ -n "$PROFILE" ]; then
    target_branch="profile/${PROFILE}"
  fi

  info "Neovim target branch: ${BOLD}${target_branch}${NC}"

  if [ -d "${NVIM_CONFIG_DIR}/.git" ]; then
    info "Updating existing nvim config..."
    if git -C "${NVIM_CONFIG_DIR}" show-ref --verify --quiet "refs/heads/${target_branch}"; then
      git -C "${NVIM_CONFIG_DIR}" checkout "${target_branch}" 2>/dev/null || true
    elif git -C "${NVIM_CONFIG_DIR}" show-ref --verify --quiet "refs/remotes/origin/${target_branch}"; then
      git -C "${NVIM_CONFIG_DIR}" checkout -b "${target_branch}" "origin/${target_branch}" 2>/dev/null || true
    else
      warn "Branch '${target_branch}' not found in local or remote; attempting fallback to core..."
      git -C "${NVIM_CONFIG_DIR}" checkout core 2>/dev/null || git -C "${NVIM_CONFIG_DIR}" checkout main 2>/dev/null || true
    fi
    git -C "${NVIM_CONFIG_DIR}" pull --ff-only || true
  else
    [ -d "${NVIM_CONFIG_DIR}" ] && mv "${NVIM_CONFIG_DIR}" "${NVIM_CONFIG_DIR}.bak"
    info "Cloning nvim repository (branch: ${target_branch})..."
    if ! git clone -b "${target_branch}" "https://github.com/${GITHUB_USER}/nvim.git" "${NVIM_CONFIG_DIR}" 2>/dev/null; then
      warn "Could not clone branch '${target_branch}' directly; cloning default and attempting checkout..."
      git clone "https://github.com/${GITHUB_USER}/nvim.git" "${NVIM_CONFIG_DIR}"
      git -C "${NVIM_CONFIG_DIR}" checkout "${target_branch}" 2>/dev/null || \
      git -C "${NVIM_CONFIG_DIR}" checkout core 2>/dev/null || true
    fi
  fi

  if command -v nvim >/dev/null 2>&1; then
    info "Syncing Neovim Lazy.nvim plugins headless..."
    nvim --headless "+Lazy! sync" +qa || true
  fi
  success "Neovim configuration ready (branch: $(git -C "${NVIM_CONFIG_DIR}" branch --show-current 2>/dev/null || echo 'default'))."
}

# ------------------------------------------------------------------------------
# 5. Setup Tmux (Ezlmt/tmux) & TPM
# ------------------------------------------------------------------------------
setup_tmux() {
  info "Setting up Tmux configuration (Ezlmt/tmux)..."
  TMUX_CONFIG_DIR="${HOME}/.config/tmux"

  if [ -d "${TMUX_CONFIG_DIR}/.git" ]; then
    info "Updating existing tmux config..."
    git -C "${TMUX_CONFIG_DIR}" pull --ff-only || true
  else
    [ -d "${TMUX_CONFIG_DIR}" ] && mv "${TMUX_CONFIG_DIR}" "${TMUX_CONFIG_DIR}.bak"
    git clone "https://github.com/${GITHUB_USER}/tmux.git" "${TMUX_CONFIG_DIR}"
  fi

  # Install TPM
  TPM_DIR="${TMUX_CONFIG_DIR}/plugins/tpm"
  if [ ! -f "${TPM_DIR}/tpm" ]; then
    info "Cloning Tmux Plugin Manager (TPM)..."
    rm -rf "${TPM_DIR}"
    git clone https://github.com/tmux-plugins/tpm "${TPM_DIR}"
  fi

  # Clean up any empty submodule placeholder directories so TPM won't falsely treat them as installed
  for p in "${TMUX_CONFIG_DIR}/plugins"/*; do
    if [ -d "$p" ] && [ ! -d "$p/.git" ]; then
      rm -rf "$p"
    fi
  done

  # Install Tmux plugins headless
  if [ -x "${TPM_DIR}/bin/install_plugins" ]; then
    info "Installing Tmux plugins..."
    export TMUX_PLUGIN_MANAGER_PATH="${TMUX_CONFIG_DIR}/plugins/"
    tmux start-server \; source-file "${TMUX_CONFIG_DIR}/tmux.conf" 2>/dev/null || true
    "${TPM_DIR}/bin/install_plugins" || true
  fi
  success "Tmux configuration ready."
}

# ------------------------------------------------------------------------------
# 6. Setup Yazi (Ezlmt/yazi)
# ------------------------------------------------------------------------------
setup_yazi() {
  info "Setting up Yazi file manager configuration (Ezlmt/yazi)..."
  YAZI_CONFIG_DIR="${HOME}/.config/yazi"

  if [ -d "${YAZI_CONFIG_DIR}/.git" ]; then
    info "Updating existing yazi config..."
    git -C "${YAZI_CONFIG_DIR}" pull --ff-only || true
  else
    [ -d "${YAZI_CONFIG_DIR}" ] && mv "${YAZI_CONFIG_DIR}" "${YAZI_CONFIG_DIR}.bak"
    git clone "https://github.com/${GITHUB_USER}/yazi.git" "${YAZI_CONFIG_DIR}"
  fi

  # Deploy packages via ya
  if command -v ya >/dev/null 2>&1; then
    info "Deploying Yazi packages via ya pkg..."
    ya pkg install || true
  fi
  success "Yazi configuration ready."
}

# ------------------------------------------------------------------------------
# 7. Shell Default Switch & Termux Font Setup
# ------------------------------------------------------------------------------
setup_shell() {
  if is_termux; then
    if [ ! -f "${HOME}/.termux/font.ttf" ]; then
      info "Installing Maple Mono NF Nerd Font for Termux..."
      mkdir -p "${HOME}/.termux"
      local tmp_zip="${TMPDIR:-${HOME}/.cache}/MapleMono-NF.zip"
      if curl -fsSL -o "$tmp_zip" "https://github.com/subframe7536/maple-font/releases/latest/download/MapleMono-NF.zip"; then
        unzip -q -o "$tmp_zip" "MapleMono-NF-Regular.ttf" -d "${HOME}/.termux/" 2>/dev/null || true
        if [ -f "${HOME}/.termux/MapleMono-NF-Regular.ttf" ]; then
          mv -f "${HOME}/.termux/MapleMono-NF-Regular.ttf" "${HOME}/.termux/font.ttf"
          command -v termux-reload-settings >/dev/null 2>&1 && termux-reload-settings || true
          success "Installed Maple Mono NF to ~/.termux/font.ttf"
        fi
        rm -f "$tmp_zip"
      fi
    fi
    info "Setting Termux default login shell to Zsh..."
    chsh -s zsh || true
    return 0
  fi

  if command -v zsh >/dev/null 2>&1; then
    ZSH_PATH="$(command -v zsh)"
    if [ "$SHELL" != "$ZSH_PATH" ]; then
      info "Changing default login shell to Zsh..."
      chsh -s "$ZSH_PATH" || warn "Could not change login shell automatically. Run: chsh -s $ZSH_PATH"
    fi
  fi
}

# ------------------------------------------------------------------------------
# Main Execution
# ------------------------------------------------------------------------------
main() {
  parse_args "$@"
  resolve_profile

  info "Active Profile: ${BOLD}${GREEN}${PROFILE}${NC}"
  checkout_dotfiles_branch

  install_packages
  setup_zsh
  link_dotfiles
  setup_tmux
  setup_nvim
  setup_yazi
  setup_shell

  echo
  echo -e "${GREEN}${BOLD}==============================================================${NC}"
  echo -e "${GREEN}${BOLD}   All Done! Development environment configured successfully!  ${NC}"
  echo -e "${GREEN}${BOLD}   Profile: ${PROFILE}                                          ${NC}"
  echo -e "${GREEN}${BOLD}==============================================================${NC}"
  echo
  echo "Next steps:"
  echo "1. On your local terminal emulator (WezTerm, Ghostty, Kitty, iTerm2, etc.):"
  echo "   - Font: Set to 'Maple Mono NF' (or any Nerd Font)"
  echo "   - Ligatures: Enable ligatures support"
  echo "2. Restart your terminal or run: exec zsh"
  echo "3. Launch tmux with: tmux"
  echo "4. Launch nvim with: nvim (or alias 'n')"
  echo "5. Launch yazi with: y (or alias 'yazi')"
  echo "6. View workflow cheatsheet with: cheat (or halhelp)"
}

main "$@"
