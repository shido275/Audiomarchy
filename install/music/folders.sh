#!/bin/bash
# The folder layout every DAW can agree on.

au_ensure_folders() {
  local base="${AUDIOMARCHY_MUSIC_DIR:-$HOME/Music/Audiomarchy}"

  if au_dry; then
    au_note "[dry-run] would create $base/{Projects,Renders,Samples,Recordings,Presets}"
    return 0
  fi

  mkdir -p "$base"/{Projects,Renders,Samples,Recordings,Presets}
  mkdir -p "$HOME/.vst" "$HOME/.vst3" "$HOME/.lv2" "$HOME/.clap"
  au_ok "$base"
}
