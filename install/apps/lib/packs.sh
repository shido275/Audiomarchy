# Pack resolution. A leaf is one app, one script:
#
#   install/apps/<category>/<app>.sh
#
# Leaves tagged "# pack: core" are in the curated default set. Every leaf is
# available through "all" or "<category>-all".

au_leaf_list() {
  find "$AUDIOMARCHY_INSTALL/apps" -mindepth 2 -maxdepth 2 -type f -name '*.sh' \
    ! -path '*/lib/*' | sort
}

au_leaf_category() {
  basename "$(dirname "$1")"
}

au_leaf_is_core() {
  grep -qE '^#[[:space:]]*pack:[[:space:]]*core' "$1"
}

au_pack_categories() {
  local leaf
  while IFS= read -r leaf; do
    au_leaf_category "$leaf"
  done < <(au_leaf_list) | sort -u
}

# Every leaf belonging to one pack name.
au_pack_leaves() {
  local name=$1 leaf category
  case "$name" in
    all)
      au_leaf_list
      ;;
    core)
      while IFS= read -r leaf; do
        au_leaf_is_core "$leaf" && printf '%s\n' "$leaf"
      done < <(au_leaf_list)
      ;;
    *-all)
      category="${name%-all}"
      while IFS= read -r leaf; do
        [[ $(au_leaf_category "$leaf") == "$category" ]] && printf '%s\n' "$leaf"
      done < <(au_leaf_list)
      ;;
    *)
      while IFS= read -r leaf; do
        [[ $(au_leaf_category "$leaf") == "$name" ]] && au_leaf_is_core "$leaf" &&
          printf '%s\n' "$leaf"
      done < <(au_leaf_list)
      ;;
  esac
}

au_pack_valid_name() {
  local name=$1 category
  [[ $name == "all" || $name == "core" ]] && return 0
  if [[ $name == *-all ]]; then
    category="${name%-all}"
  else
    category="$name"
  fi
  au_pack_categories | grep -qx "$category"
}

au_pack_valid_names() {
  local category
  printf 'core\nall\n'
  while IFS= read -r category; do
    printf '%s\n%s-all\n' "$category" "$category"
  done < <(au_pack_categories)
}

# Union of several packs, deduplicated.
au_pack_resolve() {
  local pack
  for pack in "$@"; do
    au_pack_leaves "$pack"
  done | sort -u
}
