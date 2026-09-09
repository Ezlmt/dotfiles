# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins to load
plugins=(
  git 
  zsh-autosuggestions 
  zsh-syntax-highlighting
)

[[ -f "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

# --- FZF / Fuzzy search setup ---
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

# Smooth Zsh completion cache
zstyle ':completion:*' menu yes select
zstyle ':completion::complete:*' use-cache 1
zstyle ':completion::complete:*' cache-path ~/.zsh/cache

# --- PATH configuration ---
export PATH="$HOME/.local/bin:$HOME/go/bin:$PATH"
[[ -d /opt/homebrew/bin ]] && export PATH="/opt/homebrew/bin:$PATH"
[[ -d /opt/nvim-linux-x86_64/bin ]] && export PATH="$PATH:/opt/nvim-linux-x86_64/bin"
[[ -d "$HOME/yazi/target/debug" ]] && export PATH="$HOME/yazi/target/debug:$PATH"

# --- Zoxide (smart cd) ---
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# --- Functions & Aliases ---
# Yazi wrapper: cd to directory on exit
function y() {
	local tmp cwd; tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd" || builtin true
	command rm -f -- "$tmp"
}

alias n="nvim"
alias lg="lazygit"

# --- Google Internal Completions (conditional) ---
if [[ -f /etc/bash_completion.d/g4d ]]; then
  . /etc/bash_completion.d/p4
  . /etc/bash_completion.d/g4d
fi
if [[ -f /etc/bash_completion.d/hgd ]]; then
  source /etc/bash_completion.d/hgd
fi
if [[ -x /google/bin/releases/jetski-devs/tools/cli ]]; then
  alias jsk="/google/bin/releases/jetski-devs/tools/cli"
fi

# Machine-specific local config overrides
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
