# Ezlmt's Dotfiles

Personal development environment configuration for **Zsh**, **Powerlevel10k**, **Neovim**, **Tmux**, **Yazi**, and daily CLI workflow.

Supports **macOS**, **Ubuntu/Debian**, **Arch Linux**, and **Fedora**.

---

## 🚀 One-Command Quick Install (在新电脑上一键安装)

在新机器上打开终端，运行以下任一命令即可全自动安装所有软件依赖、克隆配置、初始化插件：

### 方式 A（推荐，基于 Git Clone）：
```bash
git clone https://github.com/Ezlmt/dotfiles.git ~/.dotfiles && cd ~/.dotfiles && ./install.sh
```

### 方式 B（极简，基于 Curl）：
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Ezlmt/dotfiles/main/install.sh)"
```

---

## 📦 包含的组件与模块

| 模块 | 仓库 / 来源 | 说明 |
| :--- | :--- | :--- |
| **Zsh** | [.zshrc](.zshrc) | Oh My Zsh + autosuggestions + syntax-highlighting + zoxide + fzf |
| **Theme** | [.p10k.zsh](.p10k.zsh) | Powerlevel10k 精美终端提示符（已调校） |
| **Neovim** | [Ezlmt/nvim](https://github.com/Ezlmt/nvim) (branch `work`) | 基于 Lazy.nvim，开箱即用的完整 IDE 配置 |
| **Tmux** | [Ezlmt/tmux](https://github.com/Ezlmt/tmux) | Catppuccin Mocha 主题 + TPM 插件自动加载 |
| **Yazi** | [Ezlmt/yazi](https://github.com/Ezlmt/yazi) | 现代 Yazi v26.x 配置（内置 smart-enter, toggle-pane, git, zoxide 等） |
| **CLI Tools** | 自动安装 | `fzf`, `ripgrep`, `fd`, `zoxide`, `lazygit`, `neovim` |

---

## 🎨 字体要求 (Nerd Fonts)

为了在终端中完美显示 Powerlevel10k 图标、Yazi 文件图标和 Neovim 符号：
- 推荐在终端应用（Terminal / iTerm2 / WezTerm / Alacritty / Windows Terminal）中将字体设置为 **Nerd Font**：
  - [MesloLGS NF](https://github.com/romkatv/powerlevel10k#meslo-nerd-font-patched-for-powerlevel10k)
  - 或 [JetBrainsMono Nerd Font](https://www.nerdfonts.com/font-downloads)

---

## 🛠 本地环境个性化覆盖

如果有特定于某台电脑的密钥、本地环境变量或公司内部别名，可以新建并写入到 `~/.zshrc.local`：
```bash
# ~/.zshrc.local 不会被 git 追踪，自动被 ~/.zshrc 读取
export MY_CUSTOM_ENV="value"
```
