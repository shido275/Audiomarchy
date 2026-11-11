# Windows plugin host.
#
# Runs after the app leaves so Wine exists, then: matching yabridge build,
# a dedicated Wine prefix, and the standard Windows VST folders registered
# with yabridgectl. Vendor licensing is deliberately not automated — iLok,
# Waves and Native Instruments all require the user's own account.

au_install_windows_plugins() {
  if ! command -v wine >/dev/null 2>&1; then
    au_pkg_add wine-staging || {
      au_warn "Wine is unavailable — Windows plugins stay disabled"
      return 0
    }
  fi

  au_pkg_add winetricks || au_note "winetricks missing — runtime helpers unavailable"

  source "$AUDIOMARCHY_INSTALL/plugins/yabridge.sh"
  au_yabridge_install || au_warn "yabridge setup incomplete — run audiomarchy plugins doctor"

  source "$AUDIOMARCHY_INSTALL/plugins/prefix.sh"
  if au_wine_prefix_init; then
    au_wine_prefix_register || au_warn "could not register the Windows plugin folders"
  else
    au_warn "no studio Wine prefix — run audiomarchy plugins prefix init"
  fi
}
