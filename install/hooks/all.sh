# Omarchy's post-update hooks keep the integration alive across
# `omarchy update`: the menu is regenerated and the studio rules are put
# back, without reinstalling packages.

au_install_hooks() {
  local dir="${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/hooks/post-update.d"
  local hook="$dir/audiomarchy-refresh.hook"

  au_say "Post-update hook"

  if au_dry; then
    au_note "[dry-run] would install $hook"
    return 0
  fi

  mkdir -p "$dir"
  cat > "$hook" <<'HOOK'
#!/bin/bash
# Keep the Audiomarchy Music menu and studio window rules in place after an
# Omarchy update. Silent on purpose: an update should not open a terminal.
if command -v audiomarchy >/dev/null 2>&1; then
  audiomarchy refresh >/dev/null 2>&1 || true
fi
HOOK
  chmod 755 "$hook"
  au_ok "$hook"
}
