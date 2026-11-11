#!/bin/bash
# PipeWire engine setup. The clock config is written by the CLI (one source
# of truth for profiles); WirePlumber gets a drop-in that keeps interfaces
# awake instead of suspending them between takes.

au_setup_pipewire() {
  au_say "PipeWire studio tuning"

  if ! command -v pipewire >/dev/null 2>&1; then
    au_warn "PipeWire is not installed — skipping engine setup"
    return 0
  fi

  au_install_file \
    "$AUDIOMARCHY_PATH/config/wireplumber/90-audiomarchy.conf" \
    "${XDG_CONFIG_HOME:-$HOME/.config}/wireplumber/wireplumber.conf.d/90-audiomarchy.conf"

  if au_dry; then
    au_note "[dry-run] would apply the balanced latency profile and restart the audio server"
    return 0
  fi

  audiomarchy audio latency balanced >/dev/null || {
    au_warn "could not write the audio profile"
    return 1
  }
  au_ok "balanced profile applied (48 kHz, 256 frames)"

  omarchy-restart-pipewire >/dev/null 2>&1 || {
    systemctl --user restart wireplumber.service pipewire.service >/dev/null 2>&1
  }
  au_ok "audio server restarted"
}
