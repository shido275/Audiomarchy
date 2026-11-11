# Studio window rules. Kept in their own file so `omarchy refresh hyprland`
# cannot silently drop them; hyprland.conf gets one marked source line.

au_install_hypr() {
  local conf="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/hyprland.conf"
  local rules="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/audiomarchy.conf"
  local line='source = ~/.config/hypr/audiomarchy.conf'
  local errors backup=""

  au_say "Studio window rules"

  au_install_file "$AUDIOMARCHY_PATH/config/hypr/audiomarchy.conf" "$rules"

  if au_dry; then
    au_note "[dry-run] would add '$line' to $conf"
    return 0
  fi

  [[ -f $conf ]] || {
    au_warn "$conf not found — add '$line' by hand"
    return 1
  }

  if grep -qF "$line" "$conf"; then
    au_ok "$conf already sources the studio rules"
  else
    backup="$conf.bak.$(date +%Y%m%d-%H%M%S)"
    cp -f "$conf" "$backup"
    printf '\n# Audiomarchy studio rules\n%s\n' "$line" >> "$conf"
    au_ok "added the studio rules to $conf"
  fi

  if command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload >/dev/null 2>&1
    errors=$(hyprctl configerrors 2>/dev/null)
    if [[ -n $errors ]]; then
      au_warn "Hyprland reported config errors:"
      printf '%s\n' "$errors" >&2
      if [[ -n $backup && $errors == *audiomarchy* ]]; then
        cp -f "$backup" "$conf"
        hyprctl reload >/dev/null 2>&1
        au_warn "removed the studio rules again — fix config/hypr/audiomarchy.conf and rerun"
        return 1
      fi
    else
      au_ok "Hyprland reloaded with no config errors"
    fi
  fi
}
