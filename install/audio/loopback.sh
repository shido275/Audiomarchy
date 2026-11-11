#!/bin/bash
# A virtual cable: a null sink plus a remap source of its monitor, so any
# app can be routed into a call/recording and the output can be captured
# without a second interface. The Linux answer to BlackHole.

au_setup_loopback() {
  if ! command -v pipewire >/dev/null 2>&1; then
    return 0
  fi

  au_say "Virtual loopback"
  au_install_file \
    "$AUDIOMARCHY_PATH/config/pipewire-pulse/90-audiomarchy-loopback.conf" \
    "${XDG_CONFIG_HOME:-$HOME/.config}/pipewire/pipewire-pulse.conf.d/90-audiomarchy-loopback.conf"

  if au_dry; then
    au_note "[dry-run] would restart pipewire-pulse to load the loopback"
    return 0
  fi

  systemctl --user restart pipewire-pulse.service >/dev/null 2>&1 &&
    au_ok "Audiomarchy Loopback available (sink + mic)" ||
    au_note "loopback will load the next time pipewire-pulse starts"
}
