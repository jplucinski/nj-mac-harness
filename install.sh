#!/usr/bin/env bash
# Symlink macos/hammerspoon to ~/.hammerspoon.
# Does not write ~/.dev-harness or ~/.config/dev-harness.
# Does not run brew bundle unless --brew is passed.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
SOURCE="${ROOT}/macos/hammerspoon"
TARGET="${HOME}/.hammerspoon"
BREWFILE="${ROOT}/bootstrap/Brewfile"

DRY_RUN=0
UNINSTALL=0
BREW=0

usage() {
  cat <<'EOF'
Usage: ./install.sh [--dry-run] [--uninstall | --brew]

  (no mode)    Symlink macos/hammerspoon to ~/.hammerspoon
  --uninstall  Remove that symlink when it points at this repo
  --brew       Run brew bundle --file bootstrap/Brewfile
  --dry-run    Print the actions and do not change the system

Default install does not run Homebrew and does not edit shell or harness files.
If ~/.hammerspoon already exists and is not this symlink, the installer stops.
EOF
}

die() {
  printf 'error: %s\n' "$1" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      ;;
    --uninstall)
      UNINSTALL=1
      ;;
    --brew)
      BREW=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
  shift
done

if [[ "$UNINSTALL" -eq 1 && "$BREW" -eq 1 ]]; then
  die "--uninstall and --brew are separate actions"
fi

if [[ ! -d "$SOURCE" || ! -f "$SOURCE/init.lua" ]]; then
  die "missing Hammerspoon config at ${SOURCE}"
fi

resolve_dir() {
  local dir="$1"
  (cd "$dir" && pwd -P)
}

SOURCE_REAL="$(resolve_dir "$SOURCE")"

symlink_target_dir() {
  local link="$1"
  local raw
  raw="$(readlink "$link")"
  if [[ "$raw" != /* ]]; then
    raw="$(cd "$(dirname "$link")" && pwd)/${raw}"
  fi
  if [[ -d "$raw" ]]; then
    resolve_dir "$raw"
    return 0
  fi
  return 1
}

is_our_symlink() {
  [[ -L "$TARGET" ]] || return 1
  local resolved
  resolved="$(symlink_target_dir "$TARGET")" || return 1
  [[ "$resolved" == "$SOURCE_REAL" ]]
}

refuse_existing() {
  if [[ -L "$TARGET" ]]; then
    printf 'error: %s is a symlink to %s, not %s.\n' "$TARGET" "$(readlink "$TARGET")" "$SOURCE_REAL" >&2
  else
    printf 'error: %s already exists and is not a symlink.\n' "$TARGET" >&2
  fi
  cat >&2 <<EOF
Move it aside, then run ./install.sh again. For example:
  mv ${TARGET} ${TARGET}.personal
This installer will not overwrite a personal Hammerspoon config.
EOF
  exit 1
}

run_brew() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf 'dry-run: brew bundle --file %s\n' "$BREWFILE"
    return 0
  fi
  if ! command -v brew >/dev/null 2>&1; then
    die "brew is not on PATH. Install Homebrew, then re-run ./install.sh --brew"
  fi
  brew bundle --file "$BREWFILE"
}

install_symlink() {
  if is_our_symlink; then
    printf 'already installed: %s -> %s\n' "$TARGET" "$SOURCE_REAL"
    return 0
  fi
  if [[ -e "$TARGET" || -L "$TARGET" ]]; then
    refuse_existing
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf 'dry-run: ln -s %s %s\n' "$SOURCE_REAL" "$TARGET"
    return 0
  fi
  ln -s "$SOURCE_REAL" "$TARGET"
  printf 'installed: %s -> %s\n' "$TARGET" "$SOURCE_REAL"
}

uninstall_symlink() {
  if [[ ! -e "$TARGET" && ! -L "$TARGET" ]]; then
    printf 'already removed: %s\n' "$TARGET"
    return 0
  fi
  if ! is_our_symlink; then
    refuse_existing
  fi
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf 'dry-run: rm %s\n' "$TARGET"
    return 0
  fi
  rm -- "$TARGET"
  printf 'removed symlink: %s\n' "$TARGET"
}

if [[ "$BREW" -eq 1 ]]; then
  run_brew
  exit 0
fi

if [[ "$UNINSTALL" -eq 1 ]]; then
  uninstall_symlink
  exit 0
fi

install_symlink
