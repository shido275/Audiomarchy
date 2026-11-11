#!/bin/bash
# Every run is logged, quiet or not, so a failed install can be read back
# after the terminal has scrolled away.

au_log_init() {
  local dir
  if (( ${AUDIOMARCHY_KEEP_LOG:-1} == 0 )); then
    AUDIOMARCHY_LOG="$(mktemp -t audiomarchy-install.XXXXXXXX)"
  elif [[ -z ${AUDIOMARCHY_LOG:-} ]]; then
    dir="${XDG_STATE_HOME:-$HOME/.local/state}/audiomarchy"
    mkdir -p "$dir"
    AUDIOMARCHY_LOG="$dir/install-$(date +%Y%m%d-%H%M%S).log"
    ln -sfn "$AUDIOMARCHY_LOG" "$dir/latest.log"
  else
    mkdir -p "$(dirname "$AUDIOMARCHY_LOG")"
  fi

  : > "$AUDIOMARCHY_LOG"
  # Mirror everything to the log without losing the live terminal output.
  exec > >(tee -a "$AUDIOMARCHY_LOG") 2>&1
}
