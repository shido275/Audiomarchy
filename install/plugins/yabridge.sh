# yabridge version selection.
#
# Upstream 5.1.1 cannot host plugins under Wine 9.22 or newer, and Arch ships
# Wine 11. The AUR's Wine 10+ branch is the only combo that actually works, so
# pick the matching build instead of installing a bridge that cannot load.
#
# Sourced by install/plugins/all.sh and by the yabridge app leaf.

au_yabridge_needs_new_wine() {
  local v major minor
  v=$(wine --version 2>/dev/null) || return 1
  v=${v#wine-}
  major=${v%%.*}
  minor=${v#*.}
  minor=${minor%%.*}
  [[ $major =~ ^[0-9]+$ && $minor =~ ^[0-9]+$ ]] || return 1
  (( major > 9 || (major == 9 && minor >= 22) ))
}

au_yabridge_install() {
  if au_yabridge_needs_new_wine; then
    if au_pkg_present yabridge && ! au_pkg_present yabridge-wine10-git; then
      au_note "Wine $(wine --version 2>/dev/null) cannot host plugins with yabridge 5.1.1"
      au_note "switching to the Wine 10+ build (yabridge-wine10-git, AUR)"
      if au_dry; then
        au_note "[dry-run] would replace yabridge with yabridge-wine10-git + yabridgectl-wine10-git"
      else
        # The AUR packages conflict with the official one; remove it first so
        # the AUR helper does not stop on an interactive conflict prompt.
        sudo pacman -R --noconfirm yabridge >/dev/null 2>&1 || true
      fi
    fi
    au_pkg_add yabridge-wine10-git yabridgectl-wine10-git || return 1
  else
    au_pkg_add yabridge || return 1
    if pacman -Si yabridgectl >/dev/null 2>&1; then
      au_pkg_add yabridgectl || true
    fi
  fi

  if ! command -v yabridgectl >/dev/null 2>&1; then
    au_warn "yabridgectl is missing — install yabridgectl-wine10-git"
    return 1
  fi
  return 0
}
