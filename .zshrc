# ==============================================================================
# Powerlevel10k Instant Prompt
# Should stay close to the top of ~/.zshrc.
# ==============================================================================
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ==============================================================================
# Zsh / Oh-My-Zsh Optimization Flags (Set BEFORE oh-my-zsh.sh)
# ==============================================================================
# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load
ZSH_THEME="powerlevel10k/powerlevel10k"

# Speed up startup: Disable compaudit security checks (safe on single-user dev machines)
ZSH_DISABLE_COMPFIX="true"

# Disable automatic update checks on shell startup (avoids latency / hang)
zstyle ':omz:update' mode reminder

# Keep PATH, fpath unique (no duplicates when sourcing repeatedly)
typeset -U path PATH fpath FPATH

# Setup Zsh completion cache directory
ZSH_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
[[ -d "$ZSH_CACHE_DIR" ]] || mkdir -p "$ZSH_CACHE_DIR"

# Zsh Completion Styles (Configured before compinit)
zstyle ':completion:*' menu yes select
zstyle ':completion::complete:*' use-cache 1
zstyle ':completion::complete:*' cache-path "$ZSH_CACHE_DIR/zcompcache"
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'

# Plugins to load (zsh-syntax-highlighting must stay at the very end)
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)

# Load Oh My Zsh
[[ -f "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

# Load P10k config immediately after prompt initialization
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ==============================================================================
# History Configuration
# ==============================================================================
HISTSIZE=50000
SAVEHIST=50000
HISTFILE="${XDG_STATE_HOME:-$HOME}/.zsh_history"
setopt EXTENDED_HISTORY          # Record timestamp and duration
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded
setopt HIST_IGNORE_ALL_DUPS      # Delete old duplicate entry if a new one is recorded
setopt HIST_FIND_NO_DUPS         # Do not display duplicates when searching history
setopt HIST_IGNORE_SPACE         # Do not record entries starting with a space
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries to the history file
setopt HIST_REDUCE_BLANKS        # Remove unnecessary blanks from each command
setopt HIST_VERIFY               # Don't execute immediately upon history expansion
setopt SHARE_HISTORY             # Share history between all active sessions
setopt INC_APPEND_HISTORY        # Write to history file immediately upon command execution

# ==============================================================================
# PATH Configuration
# ==============================================================================
export ANDROID_BUILD_TOP="$HOME/android_workspace"
export ANDROID_SKIP_AGENT_CONFIG=1

# Priority paths (using (N) nullglob: only added if directory exists)
path=(
  $HOME/.local/bin
  $HOME/go/bin
  $HOME/platform-tools(N)
  /opt/homebrew/bin(N)
  /opt/nvim-linux-x86_64/bin(N)
  $HOME/yazi/target/debug(N)
  $ANDROID_BUILD_TOP/out/host/linux-x86/bin(N)
  $path
)
export PATH

# ==============================================================================
# Modern Tools & Fuzzy Search (FZF / Zoxide / Yazi)
# ==============================================================================
# FZF integration
for fzf_keybindings in \
  "/usr/share/doc/fzf/examples/key-bindings.zsh" \
  "/opt/homebrew/opt/fzf/shell/key-bindings.zsh" \
  "/usr/local/opt/fzf/shell/key-bindings.zsh" \
  "$HOME/.fzf.zsh"; do
  if [[ -f "$fzf_keybindings" ]]; then
    source "$fzf_keybindings"
    break
  fi
done

for fzf_completion in \
  "/usr/share/doc/fzf/examples/completion.zsh" \
  "/opt/homebrew/opt/fzf/shell/completion.zsh" \
  "/usr/local/opt/fzf/shell/completion.zsh"; do
  if [[ -f "$fzf_completion" ]]; then
    source "$fzf_completion"
    break
  fi
done

# Use modern 'fd' for blazing fast FZF file & dir discovery
if command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --strip-cwd-prefix --hidden --follow --exclude .git'
fi
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --inline-info'

# Zoxide (smart cd replacement)
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# Yazi wrapper: cd to directory on exit
function y() {
  local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
  command yazi "$@" --cwd-file="$tmp"
  if cwd="$(<"$tmp")" && [[ -n "$cwd" && "$cwd" != "$PWD" && -d "$cwd" ]]; then
    builtin cd -- "$cwd"
  fi
  command rm -f -- "$tmp"
}

# Default editor
export EDITOR="nvim"
export VISUAL="nvim"

# ==============================================================================
# Aliases & Functions (General)
# ==============================================================================
alias n='nvim'
alias lg='lazygit'
alias tls='command -v tmx2 >/dev/null 2>&1 && tmx2 ls || tmux ls'

# Safe & Helpful Shortcuts
alias cp='cp -i'
alias mv='mv -i'
alias df='df -h'
alias du='du -h'

# Tmux / Tmx2 Helper
tm() {
  local session="${1:-main}"
  if command -v tmx2 >/dev/null 2>&1; then
    tmx2 new -A -s "$session"
  else
    tmux new -A -s "$session"
  fi
}

# Cheatsheet & Workflow Helper
alias cheat='halhelp'
alias cheatsheet='halhelp'
alias hhelp='halhelp'

# ==============================================================================
# Profiles & Local Overrides
# ==============================================================================
# Automatically source active profiles if present (e.g. profiles/android-hal.zsh)
if [[ -d "${HOME}/.dotfiles/profiles" ]]; then
  for profile in "${HOME}/.dotfiles/profiles"/*.zsh(N); do
    source "$profile"
  done
fi

# Machine-specific uncommitted local overrides
[[ ! -f ~/.zshrc.local ]] || source ~/.zshrc.local
