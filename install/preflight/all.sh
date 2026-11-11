# Preflight checks. Sourced by install.sh; refuses to run on anything that is
# not a stock Omarchy install.

au_preflight() {
  au_say "Checking the machine"

  [[ -d $HOME/.local/share/omarchy ]] ||
    au_die "Omarchy was not found (~/.local/share/omarchy is missing). Install Omarchy first."
  command -v omarchy &>/dev/null ||
    au_die "the 'omarchy' command is not on PATH. This overlay only runs on top of Omarchy."

  (( EUID != 0 )) || au_die "run this as your normal user, not with sudo"
  [[ -f /etc/arch-release ]] || au_warn "this does not look like Arch Linux"
  command -v pacman &>/dev/null || au_die "pacman is required"

  command -v jq &>/dev/null || au_die "jq is required (omarchy pkg add jq)"
  command -v perl &>/dev/null || au_die "perl is required for menu validation"

  if ! command -v pipewire &>/dev/null; then
    au_warn "PipeWire is not installed — the audio engine setup will be skipped"
  fi

  au_ok "Omarchy $(omarchy version 2>/dev/null | head -1 || echo 'detected')"
  au_ok "Arch Linux $(uname -m)"
}
