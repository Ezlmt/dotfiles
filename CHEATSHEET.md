# 🛠️ 开发者全能工作流速查手册 (Cheatsheet)

> **快捷打开此手册**：在终端任意位置输入 `cheat` 或 `halhelp`  
> **分类查看**：`cheat yazi` | `cheat nvim` | `cheat tmux` | `cheat hal` | `cheat git` | `cheat shell`  
> **交互式查找**：`cheat -i` (借助 fzf 极速交互查找)

---

## 目录
1. [📸 Lyric Camera HAL 日常开发核心流 (Mentor 工作流)](#1-lyric-camera-hal-日常开发核心流-mentor-工作流)
2. [🗂️ Yazi 现代终端文件管理器深度解析与配置](#2-yazi-现代终端文件管理器深度解析与配置)
3. [⚡ Neovim 现代化编辑器配置与按键速查](#3-neovim-现代化编辑器配置与按键速查)
4. [🪟 Tmux / tmx2 终端复用器 (基于你的专属配置)](#4-tmux--tmx2-终端复用器-基于你的专属配置)
5. [🐙 Lazygit 现代终端 Git TUI 神器 (极简操作指南)](#5-lazygit-现代终端-git-tui-神器-极简操作指南)
6. [🔄 代码同步与版本管理 (Repo, Git, Piper/CitC)](#6-代码同步与版本管理-repo-git-pipercitc)
7. [🐚 终端生产力与智能检索 (Shell, FZF, Zoxide)](#7-终端生产力与智能检索-shell-fzf-zoxide)
8. [🧭 市面优秀命令提示与速查工具横向对比与进阶玩法](#8-市面优秀命令提示与速查工具横向对比与进阶玩法)

---

## 1. 📸 Lyric Camera HAL 日常开发核心流 (Mentor 工作流)
> 查看分类：`cheat hal`

| 命令 | 说明 | 使用场景 / 关键优势 |
| :--- | :--- | :--- |
| `bhal` | **编译 + 推机 + 重启相机** | **最强日常连招**：Neovim 改完代码后一键完成 RBE 编译并装机生效 |
| `mlyric` | 编译 HAL APEX 模块 | 在任意目录下直接编译 `com.google.pixel.camera.hal`；未 lunch 自动补 lunch |
| `mlyric debug` | 编译带 Debug 符号的 APEX | 编译 `com.google.pixel.camera.hal.debug` |
| `uphal` | 推送 APEX 并重启相机 | 自动容错 `$OUT` 路径，带 `wait-for-device` 保护，重启 `pkill -f camera` |
| `uphal -s <serial>` | 指定手机推送 | 多台手机连接时指定目标真机序列号 |
| `alunch` | 一键加载 RBE + Lunch Target | 自动加载 `rbesetup.sh` 并执行 `lunch sasquatch-trunk_staging-userdebug` |
| `camlog` | 实时查看相机 Logcat | 自动过滤 `LyricCameraHAL`、`CameraProvider`、`CameraService` 等核心日志 |
| `chal` | 直达 HAL 源码目录 | `cd $ANDROID_BUILD_TOP/vendor/google/services/LyricCameraHAL/src` |
| `ctop` | 直达 Android 根目录 | `cd $ANDROID_BUILD_TOP` (`~/android_workspace`) |
| `cout` | 直达编译产物目录 | `cd $OUT` (`.../out/target/product/sasquatch`) |
| `mcompdb` | **生成 Clangd 编译数据库** | **LSP 神器**：生成 `compile_commands.json`，彻底消灭头文件缺失报错 |

---

## 2. 🗂️ Yazi 现代终端文件管理器深度解析与配置
> 查看分类：`cheat yazi`  
> 启动方式：终端输入 `y` (退出时自动 `cd` 进入当前浏览目录)

### 💡 核心设计理念
Yazi 是一款基于 **Rust + Lua** 开发的极速异步终端文件管理器。它采用类似 macOS Finder 的 **Miller Columns (三列视图)**：
- **左列**：父级目录
- **中列**：当前目录（当前光标所在位置）
- **右列**：文件实时预览（支持代码高亮、Markdown 渲染、图片/PDF预览）

---

### 🚀 你的个人专属自定义按键 (基于 `~/.config/yazi`)
| 按键 | 功能 | 深度说明 |
| :--- | :--- | :--- |
| `l` | **smart-enter (智能进入)** | 命中文件夹则进入；命中文件则**直接唤起 Neovim 编辑** (替代原默认 pager) |
| `T h` | **Toggle Preview (隐藏预览)** | 临时隐藏右侧预览窗，中间文件列表满屏展开，适合看长文件名 |
| `T m` | **Maximize Preview (最大化预览)** | 将右侧预览窗最大化，适合沉浸式快速浏览代码/文档 |
| `z` | **zoxide 智能跳转** | 在 Yazi 内直接呼出 zoxide，输入目录别名直接瞬移 |
| `Z` | **fzf 模糊跳转** | 在 Yazi 内调用 fzf 模糊匹配当前树下的文件与子目录 |
| `nvim` 联动 | **默认文本编辑器** | 已配置 `${EDITOR:-nvim}` 作为首选打开程序 |

---

### 📌 Yazi 通用核心快捷键备忘 (标准操作)
#### 1. 浏览与移动 (Navigation)
- `h`：返回上一层父目录
- `j` / `k`：向下 / 向上移动光标
- `l` 或 `Enter`：进入子目录或打开文件
- `gg` / `G`：跳到列表顶部 / 底部
- `Ctrl + u` / `Ctrl + d`：向上 / 向下翻半屏
- `.`：切换显示/隐藏隐藏文件 (dotfiles)
- `~`：**随时呼出 Yazi 自带的完整快捷键帮助系统！**

#### 2. 文件增删改查 (File Operations)
- `a`：**新建文件或文件夹** (输入 `foo.txt` 建文件，输入 `foo/` 建文件夹)
- `r`：重命名单个文件
- `R`：**批量重命名** (会用你的 Neovim 打开清单，修改保存后批量生效，神器！)
- `y`：复制选中文件 (Yank)
- `x`：剪切选中文件 (Cut)
- `p`：粘贴复制/剪切的文件 (Paste)
- `d`：移动到回收站 (Trash)
- `D`：永久删除 (Delete)
- `c c`：复制当前文件的绝对路径到系统剪贴板
- `c d`：复制当前文件所在目录路径

#### 3. 选择模式 (Selection)
- `Space` (空格)：选中当前文件并自动跳到下一个 (适合挑拣多个文件)
- `v`：进入 Visual 连续选择模式 (类似 Vim 的 Visual 选区)
- `V`：进入 Visual 取消选择模式
- `Ctrl + a`：全选当前目录所有文件
- `Ctrl + r`：反选当前目录文件

#### 4. 搜索与过滤 (Filter & Search)
- `/`：实时在当前目录下过滤文件名 (按 `Esc` 退出过滤)
- `s`：调用 `ripgrep` 对目录内容进行全文检索并跳转
- `S`：调用 `fd` 对当前目录树进行深度文件名查找

#### 5. 多标签管理 (Tabs)
- `t`：新建标签页 (New Tab)
- `1` ~ `9`：直接切换到第 1~9 个标签
- `[` / `]`：切换到上一个 / 下一个标签
- `w`：关闭当前标签页

#### 6. 退出与目录同步
- `q`：**退出并切换目录** (由我们配置的 `y` wrapper 支持，退出时 shell 自动 `cd` 过去)
- `Q`：仅退出 Yazi，保留 shell 原目录不变

---

## 3. ⚡ Neovim 现代化编辑器配置与按键速查
> 查看分类：`cheat nvim`  
> 启动方式：`n [file]` 或 `nvim [file]`

### 🔑 核心按键前缀
- **`<leader>`**：`Space` (空格键)
- **`<localleader>`**：`,` (逗号)
- **极速退出插入模式**：`jk` (在 Insert 模式下敲击快速切回 Normal 模式)
- **快速光标跳行**：`Shift + H` (跳至行首 `^`)，`Shift + L` (跳至行尾 `$`)
- **多窗口穿梭**：`<Ctrl-h>` / `<Ctrl-j>` / `<Ctrl-k>` / `<Ctrl-l>` (与 Tmux 无缝通用)

---

### 🔍 Snacks.nvim 搜索与拾取器 (Pickers)
| 快捷键 | 功能 | 说明 |
| :--- | :--- | :--- |
| `<leader><space>` | **Smart Find Files** | 智能全局文件检索 (优先考虑当前项目与最近打开) |
| `<leader>ff` | **Find Files** | 查找当前工程目录所有文件 |
| `<leader>/` 或 `<leader>sg` | **Live Grep** | 全工程代码全文搜索 (基于 ripgrep) |
| `<leader>,` 或 `<leader>fb` | **Buffers** | 查看并切换当前已打开的缓冲区列表 |
| `<leader>e` | **File Explorer** | 展开/折叠 Snacks 侧边栏文件树 |
| `<leader>gs` | **Git Status** | 查看当前仓库改动状态 |
| `<leader>gg` | **Lazygit** | 在 Neovim 内部弹窗呼出 Lazygit TUI |
| `<leader>z` | **Zen Mode** | 切换极简专注模式 (无杂扰全屏居中代码) |
| `<leader>cR` | **Rename File** | 重命名当前文件并同步修改磁盘路径 |
| `<Ctrl-/>` | **Toggle Terminal** | 在底部弹出/隐藏浮动终端终端窗口 |

---

### 🧬 LSP 代码智能感知与导航
| 快捷键 | 功能 | 说明 |
| :--- | :--- | :--- |
| `gd` | **Goto Definition** | 跳转到函数/变量定义处 (Snacks Picker 弹窗) |
| `gD` | **Goto Declaration** | 跳转到声明处 |
| `gr` | **References** | 查找全工程所有引用处 |
| `gI` | **Implementations** | 跳转到接口实现 |
| `<leader>ss` | **LSP Symbols** | 检索当前文件内的类、函数、变量大纲 |
| `<leader>sS` | **Workspace Symbols** | 检索整个工作区内的全局符号 |
| `]]` / `[[` | **Next / Prev Reference** | 快速在当前词的下一个/上一个引用位置跳跃 |

---

### 💡 绝招：Which-Key 实时交互按键提示
- **忘记快捷键怎么办？**：在 Normal 模式下**直接按下 `<Space>`**，不要敲其他键，等待 0.5 秒，屏幕下方会自动弹出一个精美的交互式按键菜单 (`which-key`)，提示你每一个子分类（如 `f` 是 Find，`g` 是 Git，`s` 是 Search，`t` 是 Toggle）下的所有可能按键！
- `<leader>?`：随时查看当前 Buffer 的所有局部键位映射。

---

## 4. 🪟 Tmux / tmx2 终端复用器 (基于你的专属配置)
> 查看分类：`cheat tmux`  
> 配置文件：`~/.config/tmux/tmux.conf`  
> 核心设定：**前缀键 (Prefix) 已经改为了 `Ctrl + Space`** (而非传统的 `Ctrl + b`)！

### 🖥️ 会话管理 (Sessions)
| 快捷键 / 命令 | 功能 | 说明 |
| :--- | :--- | :--- |
| `tm [session]` | 启动/附加会话 | 终端运行 `tm` 进入默认 `main` 会话，退出不丢失进程 |
| `tls` | 列出所有会话 | `tmx2 ls` 快速查看已存在的会话 |
| `Alt + s` | **新建会话** | 无需按前缀键，直接按下 `Alt + s` 即刻开新 Session |
| `Prefix + S` | **关闭当前会话** | 弹出确认框：`Kill session #S ? (y/n)` |
| `Prefix + d` | **Detach 挂起** | 退出 tmux 界面回到主终端，后台任务继续跑 |
| `Prefix + r` | **重载配置** | 重新加载 `~/.config/tmux/tmux.conf` |

---

### 🪟 窗口管理 (Windows)
| 快捷键 | 功能 | 说明 |
| :--- | :--- | :--- |
| `Alt + w` | **新建窗口** | 在当前面板所在路径打开一个全新 Tab |
| `Alt + 1` ~ `Alt + 9` | **秒切指定窗口** | 无需前缀键，直接 `Alt + 1` 跳到第 1 个 Tab |

---

### 📐 面板切换与切分 (Panes - Directional Layout)
你的 tmux 配置针对 Vim/Neovim 用户进行了深度定向映射 (`i/j/k/l` 对应 上/左/下/右)：

| 快捷键 | 功能 | 说明 |
| :--- | :--- | :--- |
| `Alt + i` | **切换到上方 Pane** | 无需前缀键，直接切向上面板 |
| `Alt + k` | **切换到下方 Pane** | 无需前缀键，直接切向下面板 |
| `Alt + j` | **切换到左侧 Pane** | 无需前缀键，直接切向左面板 |
| `Alt + l` | **切换到右侧 Pane** | 无需前缀键，直接切向右面板 |
| `Ctrl + h/j/k/l` | **Vim-Tmux 无缝穿梭** | 在 Neovim 分屏与 Tmux 分屏之间平滑自由切换！ |
| `Prefix + i` | **向上切分面板** | 在当前窗口上方分裂新面板 (保持当前路径) |
| `Prefix + k` | **向下切分面板** | 在当前窗口下方分裂新面板 (保持当前路径) |
| `Prefix + j` | **向左切分面板** | 在当前窗口左侧分裂新面板 (保持当前路径) |
| `Prefix + l` | **向右切分面板** | 在当前窗口右侧分裂新面板 (保持当前路径) |
| `Alt + o` | **关闭其他所有面板** | 只保留当前 Pane，其余全部 kill (`kill-pane -a`) |
| `Alt + b` | **面板独占成新窗口** | 将当前 Pane 抽离成独立的新 Window (`break-pane`) |

---

### 📏 面板大小调整 (Resize Panes)
| 快捷键 | 效果 |
| :--- | :--- |
| `Alt + Shift + I` (`M-I`) | 当前面板向上扩张 5 格 |
| `Alt + Shift + K` (`M-K`) | 当前面板向下扩张 5 格 |
| `Alt + Shift + J` (`M-J`) | 当前面板向左扩张 5 格 |
| `Alt + Shift + L` (`M-L`) | 当前面板向右扩张 5 格 |

---

### 📋 复制与 Vi-Mode (Copy Mode)
| 快捷键 | 功能 |
| :--- | :--- |
| `Prefix + [` | **进入复制模式** (滚动浏览历史输出) |
| `v` | 开始字符选区 (Begin Selection) |
| `Ctrl + v` | 切换矩形块选模式 (Rectangle Toggle) |
| `y` | **复制选区内容并退出** (自动同步到剪贴板) |

---

## 5. 🐙 Lazygit 现代终端 Git TUI 神器 (极简操作指南)
> 查看分类：`cheat lg` 或 `cheat lazygit`  
> 启动方式：终端输入 `lg`，或在 Neovim 内部按下 `<leader>gg`

### 💡 核心设计与五大面板
Lazygit 是当前最流行的 Go 语言编写的交互式 Git TUI 工具。它将屏幕左侧划分为 5 个核心控制面板，按数字键 **`1` ~ `5`** 或 **`[` / `]`** 可秒级切换：
1. **Status (状态)**：显示当前仓库、分支名称与远程连接状态。
2. **Files (变动文件)**：显示工作区未暂存 (Unstaged) 与已暂存 (Staged) 文件。
3. **Branches (分支管理)**：本地分支、远程分支、Tag 标签列表。
4. **Commits (提交历史)**：当前分支的 Git Commit 历史树与提交日志。
5. **Stash (暂存贮藏)**：`git stash` 保存的代码切片。

---

### 🚀 通用高频按键备忘
| 按键 | 功能 | 说明 / 场景 |
| :--- | :--- | :--- |
| `?` | **呼出全量按键菜单** | **【最强救命键】** 任何时候按问号，立即展示当前面板所有可用按键 |
| `1` ~ `5` | **秒切 1~5 号面板** | 免去多次按 Tab，直接直达对应面板 |
| `h` / `l` | **左右切换焦点** | 在左侧列表区与右侧 Diff / 内容预览区穿梭 |
| `j` / `k` | **上下移动光标** | 标准 Vim 方向键浏览列表 |
| `q` | **退出 Lazygit** | 干净关闭回到外部终端或 Neovim |

---

### 📂 1. 文件与代码暂存 (在 Files 面板: `2`)
| 按键 | 功能 | 深度说明 |
| :--- | :--- | :--- |
| `Space` | **暂存 / 取消暂存文件** | 相当于 `git add <file>` 或 `git reset <file>` |
| `a` | **暂存 / 取消全部文件** | 相当于 `git add -A` |
| `c` | **提交修改 (Commit)** | 弹出一个小输入框，打完 Commit Message 按回车即刻提交 |
| `C` | **使用 Neovim 详细提交** | 呼出 Neovim 撰写长篇提交说明与格式化消息 |
| `A` | **追加提交 (Amend)** | `git commit --amend`，把当前修改直接追加到最新 commit |
| `d` | **放弃当前文件修改** | `git checkout -- <file>`，丢弃未暂存代码 (带二次确认) |
| `s` | **Stash 全部修改** | 将当前所有改动存入暂存栈 |
| `Enter` | **深入文件查看 Diff** | **进入行级暂存 (Line Staging) 模式**，只提交某个具体函数/某几行！ |

---

### 🔍 2. 行级与代码块暂存 (在文件 Diff 视图中)
按下 `Enter` 聚焦到右侧 Diff 区后：
* `Space`：**暂存当前光标所在的代码块 (Hunk) 或单行**（实现只提交文件一部分的神器）。
* `v`：进入 **Visual 模式**，用 `j/k` 圈选特定几行代码，再按 `Space` 只暂存选中的这几行！
* `d`：放弃当前选中的这一块代码改动。
* `Esc`：退出 Diff 视图，返回左侧文件面板。

---

### 🌿 3. 分支与变基 (在 Branches 面板: `3`)
| 按键 | 功能 | 说明 |
| :--- | :--- | :--- |
| `Space` | **检出分支 (Checkout)** | 光标停在某个分支上，按空格瞬间切换过去 |
| `n` | **创建新分支 (New branch)** | 基于当前 HEAD 快速创建新分支 |
| `M` | **合并分支 (Merge)** | 将选中的分支合并入当前所在分支 |
| `r` | **变基分支 (Rebase)** | 将当前分支 Rebase 到选中的目标分支上 |
| `d` | **删除分支 (Delete)** | 删除选中的本地分支 |
| `f` | **拉取快进 (Fast-forward)** | 从远程更新当前跟踪的分支 |

---

### 📜 4. 提交历史与交互式 Rebase (在 Commits 面板: `4`)
| 按键 | 功能 | 说明 |
| :--- | :--- | :--- |
| `s` | **向下合并 (Squash down)** | 将选中的 Commit 与它的下一个 Commit 合并为一条！ |
| `f` | **修正合并 (Fixup)** | 类似 Squash，但丢弃当前提交的 commit message |
| `r` | **修改提交说明 (Reword)** | 快速重命名历史某次 commit 的信息 |
| `d` | **删除该次提交 (Drop commit)** | 交互式 Rebase 删除历史某次有 Bug 的 commit |
| `t` | **撤销该次提交 (Revert)** | 自动生成一次相反改动的反向提交 |
| `c` | **Cherry-pick 提取提交** | 把选中的 Commit 复制提取到当前分支 |
| `Enter` | **浏览该 Commit 的文件列表** | 深入查看该历史提交具体改动了哪些文件和 Diff |

---

### ☁️ 5. 远程操作 (随时可用)
* **`P`** (大写 Shift+P)：**Push** 推送当前分支到远端仓库。
* **`p`** (小写)：**Pull** 从远端仓库拉取最新变更。

---

## 6. 🔄 代码同步与版本管理 (Repo, Git, Piper/CitC)
> 查看分类：`cheat git`

| 命令 | 说明 | 使用场景 / 关键优势 |
| :--- | :--- | :--- |
| `rsync-hal` | **仅同步 LyricHAL 代码** | **日常推荐**：秒级拉取当前 HAL 模块，无需等待整个大工程 |
| `rsync-all` | 全量同步整树 | 对应 Mentor 推荐的 32 线程全量同步：`repo sync -c -j32` |
| `rst` | `repo status` | 查看当前工作区所有改动的文件 |
| `rdiff` | `repo diff` | 查看当前工作区的代码 diff |
| `rinit-lyric` | 打印 Mentor 初始化命令 | 快速查看带 superproject / partial-clone 的 repo init 备忘 |
| `lg` | `lazygit` | 终端极简 Git TUI 图形工具，快速 stage、commit、view diff |
| `fig` | `hg` | Google CitC / Piper 版本管理快捷方式 |
| `mycls` | `hg mycls` | 查看本人名下的 Changelist 列表 |

---

## 7. 🐚 终端生产力与智能检索 (Shell, FZF, Zoxide)
> 查看分类：`cheat shell`

| 快捷键 / 命令 | 说明 | 作用 |
| :--- | :--- | :--- |
| `y` | `yazi` | 终端现代文件管理器；退出时自动 `cd` 到最后浏览的目录 |
| `z <目录名>` | `zoxide` 智能跳转 | 根据历史权重秒切目录（如 `z Lyric` 直接跳转） |
| `Ctrl + T` | FZF 模糊搜索文件 | 底层已绑定 `fd`，自动跳过 `.git`，秒出搜索结果并补入命令行 |
| `Alt + C` | FZF 模糊搜索目录 | 底层已绑定 `fd`，快速选定并进入子目录 |
| `Ctrl + R` | FZF 历史命令搜索 | 高亮搜索历史执行过的命令，回车立即上屏 |
| `jsk` | Jetski CLI | 随时调起 Google Jetski AI 编程助手命令行 |

---

## 8. 🧭 市面优秀命令提示与速查工具横向对比与进阶玩法

### 1. `navi` (交互式带参 Cheatsheet - 最具创新性)
- **官网/项目**：[denisidoro/navi](https://github.com/denisidoro/navi) (Rust 编写)
- **核心特色**：不仅告诉你命令是什么，还能**交互式填参**！
  - 例如定义了：`adb -s <device> install <apk>`
  - 在终端按快捷键呼出 `navi` 选中这条命令后，navi 会自动弹出一个 fzf 列表让你选择连接的 `<device>`，再让你选择 `<apk>`，选完自动填充到终端！
- **语法极简**：采用 Markdown 或 `.cheat` 文件定义，例如：
  ```cheat
  % android, camera
  # 编译并推机 LyricCameraHAL
  bhal
  
  # 抓取相机特定日志
  adb -s <device> logcat -s LyricCameraHAL
  $ device: adb devices | awk 'NR>1 {print $1}'
  ```

### 2. `cheat.sh` (免安装、即查即用的全网知识库)
- **官网/项目**：[cheat.sh](https://cheat.sh)
- **核心特色**：**零安装依赖**，只要机器上有 `curl` 即可直接查询！
  - 查 Linux 命令：`curl cht.sh/tar`、`curl cht.sh/rsync`
  - 查编程语言语法：`curl cht.sh/python/reverse+list`、`curl cht.sh/cpp/mutex`
  - 交互模式：`curl cht.sh/:shell` (进入专用 REPL 查询环境)

### 3. `tldr` / `tealdeer` (传统 man 手册的人性化替代品)
- **官网/项目**：[tldr-pages](https://tldr.sh) / [tealdeer](https://github.com/dbrgn/tealdeer) (Rust 重写)
- **核心特色**：专门治愈 `man` 手册动辄上千行晦涩文档的痛点。
  - 输入 `tldr tar` 或 `tldr find`，不讲废话，直接给出日常开发最常用的 5~8 个标准示例用法。

### 4. `which-key.nvim` (你的 Neovim 中已经配备)
- **核心特色**：在编辑器内部实现“零记忆负担”，敲下按键触发器后，弹层动态展现后续树状选项。

### 🎯 我们的 `cheat` / `halhelp` 的定位与优势
- 我们为你编写的 `cheat` 命令整合了上述优势：
  1. **零第三方重依赖**：纯 Python3 原生运行，不需要额外编译或安装。
  2. **深度定制专属化**：直接涵盖 Mentor 的 Android 工作流、你自己的 Yazi / Neovim / Tmux 真实键位。
  3. **分类过滤 + 交互搜索**：输入 `cheat yazi` 只看 Yazi，输入 `cheat -i` 直接启动系统级 `fzf` 搜索命令！
