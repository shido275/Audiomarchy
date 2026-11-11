# Merge one generated, BEGIN/END-marked block into Omarchy's launcher file.
#
#   au_merge_menu_block <name> <block-file> <menu-jsonc>
#
# Any previous block with the same markers is replaced, so reruns never
# duplicate entries. Three guards, all necessary because Omarchy silently
# drops the whole file when it cannot parse it:
#
#   1. add the trailing comma on the entry above the block when missing
#   2. validate the merged result the way Omarchy reads it before replacing
#   3. keep a backup outside extensions/ so Omarchy never reads it

au_menu_jsonc_valid() {
  perl -0777 -pe 's#^\s*//[^\n]*(\n|$)##mg; s#,(\s*[}\]])#$1#g' "$1" |
    jq -e 'type == "object"' >/dev/null 2>&1
}

au_merge_menu_block() {
  local name=$1 block_file=$2 menu_jsonc=$3
  local merged backup_dir
  merged=$(mktemp) || return 1

  awk -v blockfile="$block_file" -v name="$name" '
    BEGIN {
      begin_marker = "// BEGIN audiomarchy " name " menu"
      end_marker = "// END audiomarchy " name " menu"
      while ((getline line < blockfile) > 0) block[++nblock] = line
    }
    index($0, begin_marker) { in_block = 1; next }
    index($0, end_marker) { in_block = 0; next }
    in_block { next }
    { lines[++n] = $0 }
    END {
      close_at = 0
      for (i = 1; i <= n; i++)
        if (lines[i] ~ /^}[[:space:]]*$/) { close_at = i; break }
      if (!close_at) exit 2

      for (i = close_at - 1; i >= 1; i--) {
        if (lines[i] ~ /^[[:space:]]*$/ || lines[i] ~ /^[[:space:]]*\/\//) continue
        sub(/[[:space:]]+$/, "", lines[i])
        if (lines[i] !~ /[,{]$/) lines[i] = lines[i] ","
        break
      }

      for (i = 1; i < close_at; i++) print lines[i]
      for (i = 1; i <= nblock; i++) print block[i]
      for (i = close_at; i <= n; i++) print lines[i]
    }
  ' "$menu_jsonc" > "$merged"
  local awk_rc=$?

  if (( awk_rc == 2 )); then
    au_warn "[$name/menu] $menu_jsonc has no closing '}' line — left untouched"
    rm -f "$merged"
    return 1
  elif (( awk_rc != 0 )); then
    au_warn "[$name/menu] could not merge into $menu_jsonc — left untouched"
    rm -f "$merged"
    return 1
  fi

  if ! au_menu_jsonc_valid "$merged"; then
    au_warn "[$name/menu] the merged menu would not parse, so $menu_jsonc was left untouched."
    au_note "Omarchy drops the whole file when it cannot parse it. Check for a"
    au_note "missing comma or a comment at the end of a line, then rerun."
    rm -f "$merged"
    return 1
  fi

  backup_dir="${XDG_STATE_HOME:-$HOME/.local/state}/audiomarchy/menu-backup"
  if mkdir -p "$backup_dir"; then
    cp -f "$menu_jsonc" "$backup_dir/omarchy-menu.before-$name.jsonc"
  fi

  # cat into the file rather than mv: keeps its inode, owner and permissions.
  cat "$merged" > "$menu_jsonc"
  local rc=$?
  rm -f "$merged"
  return "$rc"
}
