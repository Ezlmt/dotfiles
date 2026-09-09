#!/usr/bin/env bash
set -e

# ==============================================================================
# Ezlmt's Automated Dotfiles & Development Environment Bootstrap
# Works on macOS, Ubuntu/Debian, Arch Linux, and Fedora
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
export PATH="${HOME}/.local/bin:${HOME}/go/bin:${PATH}"

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
        sudo apt-get install -y git curl zsh tmux ripgrep fd-find fzf build-essential || true
        sudo apt-get install -y zoxide lazygit || true

        # Symlink fd -> fdfind
        if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
          ln -sf "$(command -v fdfind)" "${HOME}/.local/bin/fd"
        fi

      elif command -v pacman >/dev/null 2>&1; then
        info "Arch Linux detected..."
        sudo pacman -S --needed --noconfirm git curl zsh tmux neovim ripgrep fd fzf zoxide lazygit yazi base-devel || true

      elif command -v dnf >/dev/null 2>&1; then
        info "Fedora detected..."
        sudo dnf install -y git curl zsh tmux neovim ripgrep fd-find fzf zoxide lazygit || true
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
      NVIM_VER="$(nvim --version 2>/dev/null | head -n 1 | grep -oE '[0-9]+\.[0-9]+' | head -n 1 || echo "0.0")"
      if [ "$(echo "$NVIM_VER < 0.10" | bc 2>/dev/null || echo "1")" -eq 1 ]; then
        info "Installing latest Neovim binary..."
        NVIM_TAR="nvim-linux-${ARCH}.tar.gz"
        curl -fsSL -o "/tmp/${NVIM_TAR}" "https://github.com/neovim/neovim/releases/latest/download/${NVIM_TAR}" || true
        if [ -f "/tmp/${NVIM_TAR}" ]; then
          mkdir -p "${HOME}/.local/nvim"
          tar -xzf "/tmp/${NVIM_TAR}" -C "${HOME}/.local/nvim" --strip-components=1
          ln -sf "${HOME}/.local/nvim/bin/nvim" "${HOME}/.local/bin/nvim"
          rm -f "/tmp/${NVIM_TAR}"
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
      ;;
  esac
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
# 3. Link Dotfiles (~/.zshrc, ~/.p10k.zsh)
# ------------------------------------------------------------------------------
link_dotfiles() {
  info "Linking shell configurations..."

  backup_and_link() {
    local src="$1"
    local dest="$2"
    if [ -e "$dest" ] && [ ! -L "$dest" ]; then
      warn "Backing up existing $dest to ${dest}.bak"
      mv "$dest" "${dest}.bak"
    fi
    ln -sf "$src" "$dest"
    success "Linked $dest -> $src"
  }

  backup_and_link "${DOTFILES_DIR}/.zshrc" "${HOME}/.zshrc"
  backup_and_link "${DOTFILES_DIR}/.p10k.zsh" "${HOME}/.p10k.zsh"
  if [ -f "${DOTFILES_DIR}/.gitconfig" ]; then
    backup_and_link "${DOTFILES_DIR}/.gitconfig" "${HOME}/.gitconfig"
  fi
}

# ------------------------------------------------------------------------------
# 4. Setup Neovim (Ezlmt/nvim)
# ------------------------------------------------------------------------------
setup_nvim() {
  info "Setting up Neovim configuration (Ezlmt/nvim)..."
  NVIM_CONFIG_DIR="${HOME}/.config/nvim"

  if [ -d "${NVIM_CONFIG_DIR}/.git" ]; then
    info "Updating existing nvim config..."
    git -C "${NVIM_CONFIG_DIR}" checkout work 2>/dev/null || true
    git -C "${NVIM_CONFIG_DIR}" pull --ff-only || true
  else
    [ -d "${NVIM_CONFIG_DIR}" ] && mv "${NVIM_CONFIG_DIR}" "${NVIM_CONFIG_DIR}.bak"
    git clone -b work "https://github.com/${GITHUB_USER}/nvim.git" "${NVIM_CONFIG_DIR}"
  fi

  if command -v nvim >/dev/null 2>&1; then
    info "Syncing Neovim Lazy.nvim plugins headless..."
    nvim --headless "+Lazy! sync" +qa || true
  fi
  success "Neovim configuration ready."
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
  if [ ! -d "${TPM_DIR}" ]; then
    info "Cloning Tmux Plugin Manager (TPM)..."
    git clone https://github.com/tmux-plugins/tpm "${TPM_DIR}"
  fi

  # Install Tmux plugins headless
  if [ -x "${TPM_DIR}/bin/install_plugins" ]; then
    info "Installing Tmux plugins..."
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
# 7. Shell Default Switch
# ------------------------------------------------------------------------------
setup_shell() {
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
  echo -e "${GREEN}${BOLD}==============================================================${NC}"
  echo
  echo "Next steps:"
  echo "1. Make sure your terminal is configured with a Nerd Font (e.g. JetBrainsMono NF, MesloLGS NF)"
  echo "2. Restart your terminal or run: exec zsh"
  echo "3. Launch tmux with: tmux"
  echo "4. Launch nvim with: nvim (or alias 'n')"
  echo "5. Launch yazi with: y (or alias 'yazi')"
}

main "$@"
