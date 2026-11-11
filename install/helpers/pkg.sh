#!/bin/bash
# Package helpers for the app leaves. Official packages go through Omarchy's
# own helper; anything else falls back to the AUR.

# Leaves run in their own bash process, so they need the output helpers too.
source "$AUDIOMARCHY_INSTALL/helpers/ui.sh"

au_pkg_present() {
  pacman -Qq "$1" &>/dev/null
}

au_pkg_add() {
  local pkg
  for pkg in "$@"; do
    if au_pkg_present "$pkg"; then
      au_note "already installed: $pkg"
      continue
    fi
    if au_dry; then
      au_note "[dry-run] would install $pkg"
      continue
    fi
    if pacman -Si "$pkg" &>/dev/null; then
      omarchy pkg add "$pkg" || { au_fail "could not install $pkg"; return 1; }
    elif command -v yay &>/dev/null; then
      yay -S --needed --noconfirm "$pkg" || { au_fail "could not install $pkg (AUR)"; return 1; }
    elif command -v paru &>/dev/null; then
      paru -S --needed --noconfirm "$pkg" || { au_fail "could not install $pkg (AUR)"; return 1; }
    else
      au_fail "$pkg is not in the official repos and no AUR helper is installed"
      return 1
    fi
  done
}
