# Install every selected leaf. One app, one script; a failure is reported
# and the run continues, so one unavailable package cannot sink the studio.

au_install_apps() {
  local leaf name

  if [[ ! -s ${AUDIOMARCHY_LEAVES:-} ]]; then
    au_warn "no apps selected"
    return 0
  fi

  while IFS= read -r leaf; do
    name="$(basename "$leaf" .sh)"
    au_say "  $name"
    if ! bash "$leaf"; then
      au_warn "  $name failed to install"
      AUDIOMARCHY_FAILED+=("$name")
    fi
  done < "$AUDIOMARCHY_LEAVES"
}
