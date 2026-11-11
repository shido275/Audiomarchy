# Folders and launcher entries.

au_install_music_menu() {
  source "$AUDIOMARCHY_INSTALL/music/folders.sh"
  source "$AUDIOMARCHY_INSTALL/music/menu.sh"

  au_say "Studio folders"
  au_ensure_folders

  au_say "Music menu"
  if menu_build; then
    :
  else
    au_warn "the Music menu could not be written"
  fi
}
