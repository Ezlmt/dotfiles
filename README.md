# Ezlmt's Dotfiles

Personal development environment configuration for **Zsh**, **Powerlevel10k**, **Neovim**, **Tmux**, **Yazi**, and daily CLI workflow.

Supports **macOS**, **Ubuntu/Debian**, **Arch Linux**, and **Fedora**.

---

## 🚀 One-Command Quick Install (在新电脑上一键安装)

在新机器上打开终端，运行以下任一命令即可全自动安装所有软件依赖、安装字体、克隆配置、初始化插件：

### 方式 A（推荐，基于 Git Clone）：
```bash
git clone https://github.com/Ezlmt/dotfiles.git ~/.dotfiles && cd ~/.dotfiles && ./install.sh
```

### 方式 B（极简，基于 Curl）：
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Ezlmt/dotfiles/main/install.sh)"
```

---

## 🔤 终端专属字体：Maple Mono NF (连字款)

本套环境完美适配并内置了你喜爱的 **[Maple Mono NF](https://github.com/subframe7536/maple-font)**（Nerd Font + 编程连字 Ligatures）：

* `install.sh` 脚本运行期间会**自动下载并安装** `Maple Mono NF` 至系统字体库：
  * macOS: `~/Library/Fonts/`
  * Linux: `~/.local/share/fonts/MapleMono-NF/`
* **终端软件设置说明**：
  在终端应用（Terminal / WezTerm / iTerm2 / Kitty / Windows Terminal / Alacritty 等）的字体设置中：
  * **字体名称 (Font Family)**：选择 `Maple Mono NF`
  * **连字开关 (Ligatures)**：确保勾选启用连字（Ligatures / Calt 特性启用，如 `->`, `!=`, `==`, `/*` 连字效果）

---

## 📦 包含的组件与模块

| 模块 | 仓库 / 来源 | 说明 |
| :--- | :--- | :--- |
| **Font** | [subframe7536/maple-font](https://github.com/subframe7536/maple-font) | **Maple Mono NF**（连字版 + Nerd Font 图标）自动下载安装 |
| **Zsh** | [.zshrc](.zshrc) | Oh My Zsh + autosuggestions + syntax-highlighting + zoxide + fzf |
| **Theme** | [.p10k.zsh](.p10k.zsh) | Powerlevel10k 精美终端提示符（已调校） |
| **Neovim** | [Ezlmt/nvim](https://github.com/Ezlmt/nvim) (branch `work`) | 基于 Lazy.nvim，开箱即用的完整 IDE 配置 |
| **Tmux** | [Ezlmt/tmux](https://github.com/Ezlmt/tmux) | Catppuccin Mocha 主题 + TPM 插件自动加载 |
| **Yazi** | [Ezlmt/yazi](https://github.com/Ezlmt/yazi) | 现代 Yazi v26.x 配置（内置 smart-enter, toggle-pane, git, zoxide 等） |
| **CLI Tools** | 自动安装 | `fzf`, `ripgrep`, `fd`, `zoxide`, `lazygit`, `neovim` |

---

## 🛠 本地环境个性化覆盖

如果有特定于某台电脑的密钥、本地环境变量或公司内部别名，可以新建并写入到 `~/.zshrc.local`：
```bash
# ~/.zshrc.local 不会被 git 追踪，自动被 ~/.zshrc 读取
export MY_CUSTOM_ENV="value"
```
