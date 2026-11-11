#!/bin/bash
# File helpers: never overwrite a user file without leaving a timestamped
# copy beside it.

au_backup() {
  local file=$1
  [[ -f $file ]] || return 0
  local bak="$file.bak.$(date +%Y%m%d-%H%M%S)"
  cp -f "$file" "$bak" && au_note "backed up $(basename "$file") -> $(basename "$bak")"
}

au_install_file() {
  local src=$1 dest=$2 mode=${3:-644}
  if au_dry; then
    au_note "[dry-run] would install $dest"
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  au_backup "$dest"
  install -m "$mode" "$src" "$dest"
}

# Content on stdin. In a dry run it is echoed instead of written, so the
# preview is the real content.
au_write_file() {
  local dest=$1
  if au_dry; then
    au_note "[dry-run] would write $dest"
    sed 's/^/    | /'
    return 0
  fi
  mkdir -p "$(dirname "$dest")"
  au_backup "$dest"
  cat > "$dest"
}
