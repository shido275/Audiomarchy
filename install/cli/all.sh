# Install the audiomarchy CLI into /usr/local/bin.

au_install_cli() {
  local src="$AUDIOMARCHY_PATH/bin/audiomarchy"

  [[ -f $src ]] || au_die "bin/audiomarchy is missing from the checkout"

  if au_dry; then
    au_note "[dry-run] would install /usr/local/bin/audiomarchy"
    return 0
  fi

  au_say "Installing the audiomarchy CLI"
  sudo install -m 755 "$src" /usr/local/bin/audiomarchy
  au_ok "/usr/local/bin/audiomarchy"
}
