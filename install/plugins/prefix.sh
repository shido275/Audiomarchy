# A dedicated Wine prefix for audio.
#
# Keeping plugins out of ~/.wine means a plugin installer cannot break other
# Wine apps, and an iLok machine ID stays tied to one prefix (which makes the
# backup/restore worth something).
#
# Sourced by install/plugins/all.sh.

au_wine_prefix_file() {
  printf '%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}/audiomarchy/wine-prefix"
}

au_wine_prefix_read() {
  local file
  if [[ -n ${AUDIOMARCHY_WINE_PREFIX:-} ]]; then
    printf '%s\n' "$AUDIOMARCHY_WINE_PREFIX"
    return 0
  fi
  file=$(au_wine_prefix_file)
  if [[ -s $file ]]; then
    head -1 "$file"
    return 0
  fi
  printf '%s\n' "$HOME/.wine-audiomarchy"
}

au_wine_prefix_init() {
  local prefix dir
  prefix=$(au_wine_prefix_read)

  if au_dry; then
    au_note "[dry-run] would create the Wine prefix $prefix"
    return 0
  fi

  if [[ ! -f $prefix/system.reg ]]; then
    mkdir -p "$(dirname "$prefix")" || return 1
    # Skip Wine's Mono/Gecko prompts; plugin installers do not need them and
    # the dialogs block an unattended install.
    if ! WINEPREFIX="$prefix" WINEDEBUG=-all WINEDLLOVERRIDES="mscoree,mshtml=" \
      wineboot -u >/dev/null 2>&1; then
      au_fail "wineboot failed for $prefix"
      return 1
    fi
    WINEPREFIX="$prefix" WINEDEBUG=-all wine reg add 'HKCU\Software\Wine' \
      /v Version /t REG_SZ /d win10 /f >/dev/null 2>&1 || true
    au_ok "Wine prefix created: $prefix"
  else
    au_note "Wine prefix ready: $prefix"
  fi

  for dir in \
    "drive_c/Program Files/Common Files/VST3" \
    "drive_c/Program Files/Common Files/VST2" \
    "drive_c/Program Files/VstPlugins" \
    "drive_c/Program Files/Steinberg/VSTPlugins"; do
    mkdir -p "$prefix/$dir"
  done

  mkdir -p "$(dirname "$(au_wine_prefix_file)")"
  printf '%s\n' "$prefix" > "$(au_wine_prefix_file)"
  return 0
}

au_wine_prefix_register() {
  local prefix ctl dir
  prefix=$(au_wine_prefix_read)
  ctl=$(command -v yabridgectl 2>/dev/null) || {
    au_warn "yabridgectl is missing — cannot register plugin folders"
    return 1
  }

  if au_dry; then
    au_note "[dry-run] would register the Windows VST folders with yabridgectl"
    return 0
  fi

  for dir in \
    "$prefix/drive_c/Program Files/Common Files/VST3" \
    "$prefix/drive_c/Program Files/Common Files/VST2" \
    "$prefix/drive_c/Program Files/VstPlugins" \
    "$prefix/drive_c/Program Files/Steinberg/VSTPlugins"; do
    [[ -d $dir ]] || mkdir -p "$dir"
    "$ctl" add "$dir" >/dev/null 2>&1 || au_note "yabridgectl did not add $dir"
  done
  au_ok "registered the Windows VST folders with yabridgectl"
  return 0
}
