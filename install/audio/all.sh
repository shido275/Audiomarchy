# The part that makes this a studio rather than a package list: realtime
# privileges, a PipeWire engine that does not suspend devices, and a virtual
# loopback cable. Sourced by install.sh.

au_install_audio() {
  source "$AUDIOMARCHY_INSTALL/audio/realtime.sh"
  source "$AUDIOMARCHY_INSTALL/audio/pipewire.sh"
  source "$AUDIOMARCHY_INSTALL/audio/loopback.sh"

  au_setup_realtime
  au_setup_pipewire
  au_setup_loopback
}
