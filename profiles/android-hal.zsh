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
# 2. Android Navigation
# ------------------------------------------------------------------------------
ctop() { cd "${ANDROID_BUILD_TOP:-$HOME/android_workspace}"; }
chal() { cd "${ANDROID_BUILD_TOP:-$HOME/android_workspace}/vendor/google/services/LyricCameraHAL/src"; }
cout() { cd "${OUT:-${ANDROID_BUILD_TOP:-$HOME/android_workspace}/out/target/product/sasquatch}"; }

# ------------------------------------------------------------------------------
# 3. Build & Target Lunch (RBE + Sasquatch)
# ------------------------------------------------------------------------------
alunch() {
  local top="${ANDROID_BUILD_TOP:-$HOME/android_workspace}"
  local target="${1:-sasquatch-trunk_staging-userdebug}"
  if [[ ! -d "$top" ]]; then
    echo "❌ ANDROID_BUILD_TOP directory not found: $top"
    return 1
  fi
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
  echo "🍱 Lunching $target ..."
  lunch "$target"
  local ret=$?
  builtin cd -- "$orig"
  return $ret
}

# ------------------------------------------------------------------------------
# 4. Compilation & Deployment
# ------------------------------------------------------------------------------
# Compile Lyric Camera HAL APEX
mlyric() {
  local top="${ANDROID_BUILD_TOP:-$HOME/android_workspace}"
  if [[ -z "$TARGET_PRODUCT" || -z "$OUT" ]]; then
    echo "ℹ️ Build environment not lunched. Auto-lunching sasquatch-trunk_staging-userdebug..."
    alunch || return 1
  fi
  local module="com.google.pixel.camera.hal"
  if [[ "$1" == "debug" ]]; then
    module="com.google.pixel.camera.hal.debug"
    shift
  fi
  echo "🔨 [RBE] Building module: $module ..."
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
  local top="${ANDROID_BUILD_TOP:-$HOME/android_workspace}"
  echo "🔄 Syncing full Android tree (-c -j32)..."
  (builtin cd -- "$top" && repo sync -c -j32 "$@")
}

rsync-hal() {
  local top="${ANDROID_BUILD_TOP:-$HOME/android_workspace}"
  echo "🔄 Syncing LyricCameraHAL repo only..."
  (builtin cd -- "$top" && repo sync -c -j8 vendor/google/services/LyricCameraHAL/src "$@")
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
  local top="${ANDROID_BUILD_TOP:-$HOME/android_workspace}"
  echo "🔨 Generating compile_commands.json for Clangd LSP..."
  (
    builtin cd -- "$top" || return 1
    if [[ -z "$TARGET_PRODUCT" ]]; then
      alunch
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
