# ==============================================================================
# Profile: Android & Lyric Camera HAL Development
# Target: Pixel Camera Team / Android Platform
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Google Environment & Tooling
# ------------------------------------------------------------------------------
export EDITOR="nvim"
export VISUAL="nvim"

# CIPD Auth: Bridge gcert / LOAS credentials to CIPD (go/android-cipd-auth)
[[ -x /usr/bin/sso-cred-helper ]] && export LUCI_AUTH_CREDENTIAL_HELPER="/usr/bin/sso-cred-helper"

# Google internal completions
autoload -Uz bashcompinit && bashcompinit
[[ -f /etc/bash_completion.d/p4 ]] && source /etc/bash_completion.d/p4
[[ -f /etc/bash_completion.d/g4d ]] && source /etc/bash_completion.d/g4d
[[ -f /etc/bash_completion.d/hgd ]] && source /etc/bash_completion.d/hgd
[[ -f /etc/bash_completion.d/blaze ]] && source /etc/bash_completion.d/blaze
[[ -f /etc/bash_completion.d/build_cleaner ]] && source /etc/bash_completion.d/build_cleaner

# Google VCS & Tools Aliases
alias fig="hg"
alias mycls="hg mycls"
alias jsk="/google/bin/releases/jetski-devs/tools/cli"

# ------------------------------------------------------------------------------
# 2. Android Multi-Workspace Detection & Navigation (hws)
# ------------------------------------------------------------------------------
# Automatically detect if $PWD is inside ~/workspaces/<name>; otherwise fall
# back to $ANDROID_BUILD_TOP (defaulting to ~/android_workspace).
_hal_detect_top() {
  if [[ "$PWD" == "$HOME/workspaces/"* ]]; then
    local rel="${PWD#"$HOME/workspaces/"}"
    local ws_name="${rel%%/*}"
    if [[ -d "$HOME/workspaces/$ws_name" ]]; then
      echo "$HOME/workspaces/$ws_name"
      return 0
    fi
  fi
  echo "${ANDROID_BUILD_TOP:-$HOME/android_workspace}"
}

# Multi-Workspace Manager wrapper (handles 'hws use <name>' in current shell)
hws() {
  if [[ "${1:-}" == "use" || "${1:-}" == "cd" ]]; then
    local name="${2:-main}"
    local target_top
    if [[ "$name" == "main" || "$name" == "default" ]]; then
      target_top="$HOME/android_workspace"
    else
      target_top="$HOME/workspaces/$name"
    fi
    if [[ ! -d "$target_top" ]]; then
      echo "❌ Workspace not found: $target_top"
      return 1
    fi
    export ANDROID_BUILD_TOP="$target_top"
    # Update or clear $OUT if it belonged to a different workspace
    if [[ -n "${OUT:-}" && "$OUT" != "$target_top/"* ]]; then
      export OUT="$target_top/out/target/product/${TARGET_PRODUCT:-sasquatch}"
    fi
    local hal_dir="$target_top/vendor/google/services/LyricCameraHAL/src"
    if [[ -d "$hal_dir" ]]; then
      builtin cd -- "$hal_dir"
    else
      builtin cd -- "$target_top"
    fi
    local branch
    branch="$(git -C "$PWD" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "-")"
    echo "🎯 Switched active workspace -> $name ($target_top) [branch: $branch]"
    return 0
  fi

  if [[ "${1:-}" == "rm" || "${1:-}" == "remove" || "${1:-}" == "del" || "${1:-}" == "delete" ]]; then
    local target_name="${@: -1}"
    local target_ws="$HOME/workspaces/$target_name"
    # If the shell is currently inside the workspace being deleted, evacuate to main first
    if [[ "$PWD" == "$target_ws" || "$PWD" == "$target_ws/"* ]]; then
      echo "ℹ️  Currently inside '$target_name'; switching shell back to 'main' before removal..."
      hws use main
    elif [[ "${ANDROID_BUILD_TOP:-}" == "$target_ws" ]]; then
      export ANDROID_BUILD_TOP="$HOME/android_workspace"
      export OUT="$ANDROID_BUILD_TOP/out/target/product/${TARGET_PRODUCT:-sasquatch}"
    fi
  fi

  "${HOME}/.local/bin/hws" "$@"
}

ctop() { cd "$(_hal_detect_top)"; }
chal() { cd "$(_hal_detect_top)/vendor/google/services/LyricCameraHAL/src"; }
cout() {
  local top="$(_hal_detect_top)"
  if [[ -n "${OUT:-}" && "$OUT" == "$top/"* ]]; then
    cd "$OUT"
  else
    cd "$top/out/target/product/sasquatch"
  fi
}

# ------------------------------------------------------------------------------
# 3. Build & Target Lunch (RBE + Sasquatch)
# ------------------------------------------------------------------------------
alunch() {
  local top="$(_hal_detect_top)"
  local target="${1:-sasquatch-trunk_staging-userdebug}"
  if [[ ! -d "$top" ]]; then
    echo "❌ ANDROID_BUILD_TOP directory not found: $top"
    return 1
  fi
  export ANDROID_BUILD_TOP="$top"
  local orig="$PWD"
  builtin cd -- "$top"
  if [[ -f "build/make/rbesetup.sh" ]]; then
    source build/make/rbesetup.sh
  elif [[ -f "build/make/envsetup.sh" ]]; then
    source build/make/envsetup.sh
  elif [[ -f "build/envsetup.sh" ]]; then
    source build/envsetup.sh
  else
    echo "❌ Error: envsetup/rbesetup script not found in $top"
    builtin cd -- "$orig"
    return 1
  fi
  echo "🍱 Lunching $target in $top ..."
  lunch "$target"
  local ret=$?
  builtin cd -- "$orig"
  return $ret
}

# ------------------------------------------------------------------------------
# 4. Compilation & Deployment
# ------------------------------------------------------------------------------
# Compile Lyric Camera HAL APEX (workspace-aware)
mlyric() {
  local top="$(_hal_detect_top)"
  local base_ws="${HWS_BASE_WS:-$HOME/android_workspace}"
  if [[ "$top" == "$HOME/workspaces/"* && -d "$base_ws" ]]; then
    local _fast_dir
    for _fast_dir in \
      "vendor/google_devices/gs-common/proprietary/camera" \
      "vendor/google/services/LyricCameraHAL/prebuilt" \
      "hardware/google/camera" \
      "hardware/google/interfaces" \
      "vendor/google/interfaces" \
      "vendor/google/libraries/pixelatoms"; do
      if [[ -d "$base_ws/$_fast_dir" ]]; then
        mkdir -p "$(dirname "$top/$_fast_dir")"
        rm -rf "${top:?}/$_fast_dir"
        cp -al "$base_ws/$_fast_dir" "$top/$_fast_dir"
      fi
    done
  fi
  if [[ -z "$TARGET_PRODUCT" || -z "$OUT" || "$OUT" != "$top/"* ]]; then
    echo "ℹ️ Lunching sasquatch-trunk_staging-userdebug for workspace: $top ..."
    ANDROID_BUILD_TOP="$top" alunch || return 1
  fi
  local module="com.google.pixel.camera.hal"
  if [[ "$1" == "debug" ]]; then
    module="com.google.pixel.camera.hal.debug"
    shift
  fi
  echo "🔨 [RBE] Building module: $module (in $top) ..."
  (builtin cd -- "$top" && m "$module" "$@")
}

# Deploy APEX & Restart Camera Service
uphal() {
  "${HOME}/.local/bin/uphal" "$@"
}

# The Ultimate Combo: Build + Deploy in one command
bhal() {
  mlyric && uphal "$@"
}

# Live Camera Logcat Viewer
camlog() {
  echo "📋 Streaming Camera / Lyric logs (Ctrl+C to stop)..."
  if command -v adb >/dev/null 2>&1; then
    adb logcat -v time -s "LyricCameraHAL" "CameraProvider" "CameraService" "libcameraservice" 2>/dev/null || \
    adb logcat -v time | grep --line-buffered -iE "lyric|camera|HAL"
  fi
}

# ------------------------------------------------------------------------------
# 5. Repo & Manifest Helpers
# ------------------------------------------------------------------------------
rsync-all() {
  local top="${HWS_BASE_WS:-$HOME/android_workspace}"
  echo "🔄 Syncing full Android tree (-c -j32)..."
  (builtin cd -- "$top" && repo sync -c -j32 "$@") && "${HOME}/.local/bin/hws" refresh
}

rsync-hal() {
  "${HOME}/.local/bin/lsync" "$@"
}

rinit-lyric() {
  echo "📋 Mentor's recommended repo init command:"
  echo 'REPO_ALLOW_SHALLOW=0 repo init -c -u sso://googleplex-android/platform/manifest -b main --use-superproject --partial-clone --partial-clone-exclude=platform/frameworks/base --clone-filter=blob:limit=100k && repo sync -c -j32'
}

alias rsync='repo sync -c -j$(nproc 2>/dev/null || echo 8)'
alias rst='repo status'
alias rdiff='repo diff'

# ------------------------------------------------------------------------------
# 6. Clangd Compilation Database (LSP Support)
# ------------------------------------------------------------------------------
mcompdb() {
  local top="$(_hal_detect_top)"
  echo "🔨 Generating compile_commands.json for Clangd LSP (in $top)..."
  (
    builtin cd -- "$top" || return 1
    if [[ -z "$TARGET_PRODUCT" || -z "$OUT" || "$OUT" != "$top/"* ]]; then
      ANDROID_BUILD_TOP="$top" alunch
    fi
    SOONG_GEN_COMPDB=1 SOONG_LINK_COMPDB_TO="$top" m nothing
    local hal_dir="$top/vendor/google/services/LyricCameraHAL/src"
    if [[ -d "$hal_dir" && -f "$top/compile_commands.json" ]]; then
      ln -sf "$top/compile_commands.json" "$hal_dir/compile_commands.json"
      echo "✅ Linked compile_commands.json to LyricCameraHAL/src/"
    fi
    echo "🎉 Clangd compilation database is ready!"
  )
}

# ------------------------------------------------------------------------------
# 7. Multi-Workstation ADB Tunnel & Switcher (3-Machine Architecture)
# ------------------------------------------------------------------------------
# Pull ADB from your own Workstation (element.mtv.corp.google.com) -> Local :5037
connect-my-ws() {
  echo "🔄 Restarting persistent ws-adb-tunnel.service (element.mtv -> :5037)..."
  systemctl --user restart ws-adb-tunnel.service
  sleep 6
  export ADB_SERVER_PORT=5037
  echo "✅ Connected to your Workstation (element.mtv.corp.google.com -> :5037)"
  adb devices -l
}

# Pull ADB from Mentor's Workstation (rogercyhsieh2.mtv.corp.google.com) -> Local :5038
connect-mentor-ws() {
  echo "🔄 Restarting persistent mentor-adb-tunnel.service (rogercyhsieh2.mtv -> :5038)..."
  systemctl --user restart mentor-adb-tunnel.service
  sleep 6
  export ANDROID_ADB_SERVER_PORT=5038
  export ADB_SERVER_PORT=5038
  echo "✅ Connected to Mentor's Workstation (rogercyhsieh2.mtv.corp.google.com -> :5038)"
  adb devices -l
}

alias use-my-ws='export ANDROID_ADB_SERVER_PORT=5037 ADB_SERVER_PORT=5037 && echo "🎯 Default ADB Target: My Workstation (element.mtv :5037)" && adb devices -l'
alias use-mentor-ws='export ANDROID_ADB_SERVER_PORT=5038 ADB_SERVER_PORT=5038 && echo "🎯 Default ADB Target: Mentor Workstation (rogercyhsieh2.mtv :5038)" && adb devices -l'

# ------------------------------------------------------------------------------
# 8. Dual-Phone ADB Device Aliases (Sasquatch A0 vs Skymap B0)
# ------------------------------------------------------------------------------
export ADB_SERIAL_SASQUATCH="68050DLFT000D7"
export ADB_SERIAL_SKYMAP="ffd2c76439364f860220e5cd14814a81"

# Switch default target phone in current shell ($ANDROID_SERIAL) — works with adb, atest, uphal, bhal
alias use-sas='export ANDROID_SERIAL="$ADB_SERIAL_SASQUATCH" && echo "📱 Active Phone: Sasquatch (A0) [$ANDROID_SERIAL]"'
alias use-a0='use-sas'
alias use-sky='export ANDROID_SERIAL="$ADB_SERIAL_SKYMAP" && echo "📱 Active Phone: Skymap (B0) [$ANDROID_SERIAL]"'
alias use-b0='use-sky'

# Direct per-phone adb wrappers (without changing $ANDROID_SERIAL)
alias adbsas='adb -s "$ADB_SERIAL_SASQUATCH"'
alias adba0='adb -s "$ADB_SERIAL_SASQUATCH"'
alias adbsky='adb -s "$ADB_SERIAL_SKYMAP"'
alias adbb0='adb -s "$ADB_SERIAL_SKYMAP"'

# ------------------------------------------------------------------------------
# 9. Automatic '&&' Command Chain Visual Divider (fff)
# ------------------------------------------------------------------------------
# When typing 'cmd1 && cmd2' interactively, automatically injects 'fff' step
# banners between commands while keeping '↑' shell history 100% clean.
# Toggle anytime with: 'fff off' / 'fff on'
typeset -g _FFF_ORIG_BUFFER=""

_fff_accept_line() {
  _FFF_ORIG_BUFFER=""
  if [[ "$BUFFER" == *"&&"* && "$BUFFER" != *$'\n'* && -x "$HOME/.local/bin/fff" ]]; then
    local rewritten
    rewritten="$("$HOME/.local/bin/fff" --rewrite "$BUFFER" 2>/dev/null)"
    if [[ -n "$rewritten" && "$rewritten" != "$BUFFER" ]]; then
      _FFF_ORIG_BUFFER="$BUFFER"
      BUFFER="$rewritten"
    fi
  fi
  zle .accept-line
}
zle -N accept-line _fff_accept_line

zshaddhistory() {
  if [[ -n "${_FFF_ORIG_BUFFER:-}" ]]; then
    print -sr -- "${_FFF_ORIG_BUFFER%%$'\n'}"
    _FFF_ORIG_BUFFER=""
    return 1
  fi
  return 0
}

