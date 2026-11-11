#!/bin/bash
#
# Audiomarchy installer — a music-production overlay for a stock Omarchy
# system. Nothing Omarchy owns is modified: configs go to ~/.config, the
# launcher is extended through ~/.config/omarchy/extensions, and packages
# are installed the normal Arch way. Run it as your user, not root.
#
set -euo pipefail

AUDIOMARCHY_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export AUDIOMARCHY_PATH
export AUDIOMARCHY_INSTALL="$AUDIOMARCHY_PATH/install"
export AUDIOMARCHY_DRY_RUN=0
export AUDIOMARCHY_VERBOSE=0
export AUDIOMARCHY_LEAVES=""

AUDIOMARCHY_LOG=""
AUDIOMARCHY_KEEP_LOG=1
AUDIOMARCHY_LIST_PACKS=0
AUDIOMARCHY_PACKS=()
AUDIOMARCHY_FAILED=()
AUDIOMARCHY_STARTED=$SECONDS

usage() {
  cat <<'USAGE'
Usage: ./install.sh [options]

  -v, --verbose        show every package-manager line as it happens
      --dry-run        print every change without touching the system
      --pack SPEC      install exactly these packs instead of "core"
                       (core, all, <category>, <category>-all;
                       comma-separated or repeatable)
      --list-packs     list every pack with its leaf count, install nothing
      --log PATH       write the log somewhere other than
                       ~/.local/state/audiomarchy/install-<timestamp>.log
      --no-log         do not keep a log file
  -h, --help           this message

A bare run installs the curated core: a working studio, not every toy in
the tree. --pack replaces that selection, it does not add to it.
USAGE
}

while (( $# )); do
  case "$1" in
    -v|--verbose) AUDIOMARCHY_VERBOSE=1 ;;
    --dry-run) AUDIOMARCHY_DRY_RUN=1 ;;
    --pack)
      [[ $# -ge 2 ]] || { echo "--pack needs a value" >&2; exit 2; }
      IFS=',' read -ra _packs <<< "$2"
      AUDIOMARCHY_PACKS+=("${_packs[@]}")
      shift
      ;;
    --pack=*)
      IFS=',' read -ra _packs <<< "${1#*=}"
      AUDIOMARCHY_PACKS+=("${_packs[@]}")
      ;;
    --list-packs) AUDIOMARCHY_LIST_PACKS=1 ;;
    --log)
      [[ $# -ge 2 ]] || { echo "--log needs a path" >&2; exit 2; }
      AUDIOMARCHY_LOG="$2"
      shift
      ;;
    --log=*) AUDIOMARCHY_LOG="${1#*=}" ;;
    --no-log) AUDIOMARCHY_KEEP_LOG=0 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; echo >&2; usage >&2; exit 2 ;;
  esac
  shift
done

export AUDIOMARCHY_DRY_RUN AUDIOMARCHY_VERBOSE

source "$AUDIOMARCHY_INSTALL/helpers/ui.sh"
source "$AUDIOMARCHY_INSTALL/helpers/log.sh"
source "$AUDIOMARCHY_INSTALL/helpers/files.sh"
source "$AUDIOMARCHY_INSTALL/helpers/pkg.sh"
source "$AUDIOMARCHY_INSTALL/apps/lib/packs.sh"

if (( AUDIOMARCHY_LIST_PACKS )); then
  printf 'core%24s %d leaves (the default)\n' "" "$(au_pack_leaves core | wc -l)"
  printf 'all%25s %d leaves (everything in the tree)\n' "" "$(au_pack_leaves all | wc -l)"
  echo
  while IFS= read -r _category; do
    printf '%-22s %2d core / %2d total\n' \
      "$_category" \
      "$(au_pack_leaves "$_category" | wc -l)" \
      "$(au_pack_leaves "$_category-all" | wc -l)"
  done < <(au_pack_categories)
  exit 0
fi

if (( ${#AUDIOMARCHY_PACKS[@]} == 0 )); then
  AUDIOMARCHY_PACKS=(core)
fi

for _pack in "${AUDIOMARCHY_PACKS[@]}"; do
  if ! au_pack_valid_name "$_pack"; then
    au_fail "unknown pack: $_pack"
    au_note "valid packs:"
    au_pack_valid_names | sed 's/^/  /' >&2
    exit 2
  fi
done

AUDIOMARCHY_LEAVES="$(mktemp -t audiomarchy-leaves.XXXXXXXX)"
export AUDIOMARCHY_LEAVES
au_pack_resolve "${AUDIOMARCHY_PACKS[@]}" | sort -u > "$AUDIOMARCHY_LEAVES"

_au_cleanup() {
  local code=$?
  rm -f "$AUDIOMARCHY_LEAVES"
  (( AUDIOMARCHY_KEEP_LOG )) || rm -f "$AUDIOMARCHY_LOG"
  if (( code != 0 )); then
    au_fail "install aborted (exit $code)"
    if [[ -n ${AUDIOMARCHY_LOG:-} ]]; then
      au_note "full log: $AUDIOMARCHY_LOG"
    fi
  fi
  exit "$code"
}
trap _au_cleanup EXIT

au_log_init
export AUDIOMARCHY_LOG

au_banner() {
  cat <<'BANNER'
   _         _ _                 _
  / \  _   _| | |_ ___  _ __ ___(_) __ _ _ __ _   _
 / _ \| | | | | __/ _ \| '_ ` _ \| |/ _` | '__| | | |
/ ___ \ |_| | | || (_) | | | | | | | (_| | |  | |_| |
/_/   \_\__,_|_|\__\___/|_| |_| |_|_|\__,_|_|   \__, |
                                               |___/
BANNER
  printf '  %sthe producer\x27s omakase — an overlay for Omarchy%s\n\n' "$AU_DIM" "$AU_RESET"
}
au_banner

if au_dry; then
  au_warn "dry run: no package, file or service will be changed"
fi

source "$AUDIOMARCHY_INSTALL/preflight/all.sh"
au_preflight

# One password prompt, up front. Everything after this is unattended.
if ! au_dry; then
  if ! sudo -n true 2>/dev/null; then
    au_say "Administrator access is needed to install packages"
    sudo -v
  fi
  ( while kill -0 "$$" 2>/dev/null; do sudo -n true 2>/dev/null; sleep 60; done ) &
  _au_sudo_keepalive=$!
fi

au_say "Installing apps ($(wc -l < "$AUDIOMARCHY_LEAVES") selected, packs: ${AUDIOMARCHY_PACKS[*]})"
source "$AUDIOMARCHY_INSTALL/apps/all.sh"
au_install_apps

source "$AUDIOMARCHY_INSTALL/cli/all.sh"
au_install_cli

source "$AUDIOMARCHY_INSTALL/audio/all.sh"
au_install_audio

source "$AUDIOMARCHY_INSTALL/music/all.sh"
au_install_music_menu

source "$AUDIOMARCHY_INSTALL/hypr/all.sh"
au_install_hypr

source "$AUDIOMARCHY_INSTALL/hooks/all.sh"
au_install_hooks

# Keep our own copy, so updates and refreshes work even if the checkout the
# user ran this from is later moved or deleted.
if au_dry; then
  au_note "[dry-run] would copy the repo to ~/.local/share/audiomarchy/repo"
else
  _state="${XDG_STATE_HOME:-$HOME/.local/state}/audiomarchy"
  mkdir -p "$_state"
  printf '%s\n' "${AUDIOMARCHY_PACKS[@]}" | sort -u > "$_state/installed-packs"
  if [[ -e $AUDIOMARCHY_PATH/.git ]] &&
     _commit=$(git -C "$AUDIOMARCHY_PATH" rev-parse HEAD 2>/dev/null); then
    printf '%s\n' "$_commit" > "$_state/installed-commit"
  fi
  _dest="$HOME/.local/share/audiomarchy/repo"
  # `audiomarchy update` reruns the installer *from* the installed copy.
  # Deleting that directory mid-run would pull the script out from under
  # bash, so only copy when this is a different checkout.
  if [[ -d $_dest && $(cd "$_dest" && pwd -P) == "$(cd "$AUDIOMARCHY_PATH" && pwd -P)" ]]; then
    au_note "running from the installed copy — repo already current"
  else
    rm -rf "$_dest"
    mkdir -p "$HOME/.local/share/audiomarchy"
    cp -a "$AUDIOMARCHY_PATH" "$_dest"
    au_ok "repo copied to ~/.local/share/audiomarchy/repo"
  fi
fi

if (( ${#AUDIOMARCHY_FAILED[@]} > 0 )); then
  au_warn "${#AUDIOMARCHY_FAILED[@]} app(s) failed: ${AUDIOMARCHY_FAILED[*]}"
fi

au_say "Done in $(( SECONDS - AUDIOMARCHY_STARTED ))s"
cat <<'NEXT'

  Your studio menu is under Music in the Omarchy launcher
  (SUPER + SPACE, then "Music"). If you were added to the realtime
  group today, log out and back in before your first session.

  Next:
    audiomarchy doctor              check the whole audio path
    audiomarchy audio latency low   tighter buffers for recording
    audiomarchy session start       focus mode for a session
    audiomarchy project new "Idea"  scaffold a project folder

NEXT
au_note "log: $AUDIOMARCHY_LOG"
