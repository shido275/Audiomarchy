#!/bin/bash
# Realtime privileges: the package ships the limits (rtprio 95, memlock
# unlimited); the user still has to be in its group, and PAM only applies
# that at the next login.

au_setup_realtime() {
  au_say "Realtime audio privileges"

  if ! au_pkg_present realtime-privileges; then
    au_pkg_add realtime-privileges || {
      au_warn "realtime-privileges could not be installed"
      return 1
    }
  fi

  if au_dry; then
    au_note "[dry-run] would add $USER to the realtime group"
    return 0
  fi

  if id -nG "$USER" | grep -qw realtime; then
    au_ok "$USER is in the realtime group"
  else
    sudo usermod -aG realtime "$USER" ||
      { au_warn "could not add $USER to the realtime group"; return 1; }
    au_ok "added $USER to the realtime group"
    au_note "log out and back in before recording — limits apply at login"
  fi
}
