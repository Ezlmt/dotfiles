# Ezlmt's Dotfiles

Automated, cross-platform personal development environment configuration for **Zsh**, **Powerlevel10k**, **Neovim**, **Tmux**, **Yazi**, and daily CLI workflows.

Supports **macOS**, **Ubuntu/Debian**, **Arch Linux**, and **Fedora**.

---

## 🚀 One-Command Bootstrap (Install on a New Machine)

On your new computer, open a terminal and run either of the following commands:

### Option 1 (Recommended via Git Clone):
```bash
git clone https://github.com/Ezlmt/dotfiles.git ~/.dotfiles && cd ~/.dotfiles && ./install.sh
```

### Option 2 (Direct via Curl):
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Ezlmt/dotfiles/main/install.sh)"
```

---

## 📦 What the Installer Does

The bootstrap script (`install.sh`) executes an unattended, idempotent setup:

1. **System Packages & Core CLI Tools**:
   - Detects package manager (`brew`, `apt`, `pacman`, `dnf`).
   - Installs `git`, `curl`, `zsh`, `tmux`, `ripgrep`, `fzf`, `fd` (with `fdfind` compatibility symlink), `zoxide`, and `lazygit`.
   - Ensures modern Neovim (`>= 0.10`) and latest Yazi binary are present.

2. **Zsh & Prompt Theme**:
   - Installs [Oh My Zsh](https://github.com/ohmyzsh/ohmyzsh) unattended.
   - Clones and configures:
     - [Powerlevel10k](https://github.com/romkatv/powerlevel10k) prompt theme.
     - [zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions).
     - [zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting).
   - Safely symlinks `~/.zshrc` and `~/.p10k.zsh` (existing files are backed up to `.bak`).

3. **Neovim Configuration**:
   - Clones [Ezlmt/nvim](https://github.com/Ezlmt/nvim) on branch `work`.
   - Runs `nvim --headless "+Lazy! sync" +qa` to pre-install and compile plugins.

4. **Tmux Configuration**:
   - Clones [Ezlmt/tmux](https://github.com/Ezlmt/tmux) into `~/.config/tmux`.
   - Installs [TPM (Tmux Plugin Manager)](https://github.com/tmux-plugins/tpm).
   - Automatically installs and activates all tmux plugins (Catppuccin Mocha, vim-tmux-navigator, cpu, sensible).

5. **Yazi File Manager**:
   - Clones [Ezlmt/yazi](https://github.com/Ezlmt/yazi) into `~/.config/yazi`.
   - Runs `ya pkg install` to deploy plugins (`smart-enter`, `toggle-pane`, `git`, `starship`, `full-border`) and theme flavor (`catppuccin-mocha`).

6. **Default Shell**:
   - Switches login shell to Zsh (`chsh -s $(which zsh)`).

---

## 🗂 Components & Repositories

| Component | Repository / Source | Highlights |
| :--- | :--- | :--- |
| **Zsh** | [.zshrc](.zshrc) | Oh My Zsh, autosuggestions, syntax-highlighting, zoxide (`z`), fzf, Yazi `y()` wrapper |
| **Theme** | [.p10k.zsh](.p10k.zsh) | Powerlevel10k customized prompt layout & Git integration |
| **Neovim** | [Ezlmt/nvim](https://github.com/Ezlmt/nvim) (`work` branch) | Lazy.nvim, LSP (clangd, gopls, lua_ls, rust_analyzer), Treesitter |
| **Tmux** | [Ezlmt/tmux](https://github.com/Ezlmt/tmux) | `Ctrl-Space` prefix, Vim-style pane navigation (`Alt-h/j/k/l`), Catppuccin Mocha |
| **Yazi** | [Ezlmt/yazi](https://github.com/Ezlmt/yazi) | Yazi v26.x, fast multi-level navigation via `z` (zoxide) and `Z` (fzf) |

---

## 🔤 Terminal Font Recommendation (Client-Side)

> [!NOTE]
> When connecting over SSH, text and glyphs are rendered on your **local physical computer's terminal emulator**, not the remote host. You only need to configure the font on your local client.

For the best visual experience with Powerlevel10k icons, Neovim file tree symbols, and Yazi indicators:

* **Recommended Font**: **[Maple Mono NF](https://github.com/subframe7536/maple-font)** (Nerd Font with coding ligatures)
  * Download: [MapleMono-NF.zip](https://github.com/subframe7536/maple-font/releases/latest/download/MapleMono-NF.zip)
* **Configuration**:
  In your local terminal settings (WezTerm, Ghostty, Kitty, Alacritty, iTerm2, or Windows Terminal):
  * **Font Family**: `Maple Mono NF`
  * **Ligatures**: Enabled (enables coding ligatures like `->`, `!=`, `==`, `<!--`)

---

## 🛠 Machine-Specific Overrides

To keep private tokens, machine-specific paths, or internal work configurations out of version control, create a `~/.zshrc.local` file:

```bash
# ~/.zshrc.local is ignored by git and automatically sourced by ~/.zshrc
export LOCAL_ENV_VAR="value"
alias work="cd /path/to/private/workspace"
```
