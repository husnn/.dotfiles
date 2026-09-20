# Tint Ghostty tabs for ssh/tssh and show 🔥 hostname in the tab title.

_tinted_ssh() {
  local cmd="$1" bg="$2" title="$3"
  shift 3
  local tinted=false
  if [[ "$TERM" == *ghostty* || -n "$GHOSTTY_RESOURCES_DIR" ]]; then
    tinted=true
    printf '\033]11;%s\007' "$bg"
    printf '\033]2;%s\007' "$title"
  fi
  command "$cmd" "$@"
  local ret=$?
  if $tinted; then
    printf '\033]111\007'
    printf '\033]2;%s\007' "${PWD/#$HOME/~}"
  fi
  return $ret
}

_ssh_extract_host() {
  local arg skip=false host=""
  for arg in "$@"; do
    if $skip; then skip=false; continue; fi
    case "$arg" in
      -[bcDEeFIiJLlmOopQRSWw]) skip=true ;;
      -*) ;;
      *@*) host="${arg#*@}"; break ;;
      *) [[ -z "$host" ]] && host="$arg"; break ;;
    esac
  done
  host="${host%%:*}"
  host="${host%%.*}"
  printf '%s' "$host"
}

ssh() {
  local host cmd=tssh
  host="$(_ssh_extract_host "$@")"
  (( $+commands[tssh] )) || cmd=ssh
  if [[ -z "$host" ]]; then
    command "$cmd" "$@"
    return
  fi
  _tinted_ssh "$cmd" '#221e1e' "🔥 $host" "$@"
}

tssh() {
  ssh "$@"
}
