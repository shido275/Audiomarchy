#!/bin/bash
# Output helpers shared by install.sh and every leaf installer.

if [[ -t 1 ]]; then
  AU_BOLD=$'\033[1m'
  AU_DIM=$'\033[2m'
  AU_GREEN=$'\033[32m'
  AU_YELLOW=$'\033[33m'
  AU_RED=$'\033[31m'
  AU_PURPLE=$'\033[35m'
  AU_RESET=$'\033[0m'
else
  AU_BOLD=""
  AU_DIM=""
  AU_GREEN=""
  AU_YELLOW=""
  AU_RED=""
  AU_PURPLE=""
  AU_RESET=""
fi

au_say() { printf '%s==>%s %s\n' "$AU_PURPLE" "$AU_RESET" "$*"; }
au_ok() { printf '%s  ok%s %s\n' "$AU_GREEN" "$AU_RESET" "$*"; }
au_note() { printf '%s    %s%s\n' "$AU_DIM" "$*" "$AU_RESET"; }
au_warn() { printf '%s warn%s %s\n' "$AU_YELLOW" "$AU_RESET" "$*" >&2; }
au_fail() { printf '%sfail%s %s\n' "$AU_RED" "$AU_RESET" "$*" >&2; }

au_dry() { (( ${AUDIOMARCHY_DRY_RUN:-0} )); }
au_die() {
  au_fail "$*"
  exit 1
}
