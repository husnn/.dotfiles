# Adapted from Ghostty 1.3.1's zsh SSH integration to use tssh for the
# interactive connection. The original integration is licensed under GPLv3.
# SPDX-License-Identifier: GPL-3.0-or-later

# OpenSSH performs the compatibility checks because Ghostty's integration relies
# on `ssh -G` and an OpenSSH control connection. Once the remote terminal is
# prepared, tssh starts the interactive session and receives the same terminal
# environment options.
_ssh_has_remote_command() {
  local arg
  local destination_seen=false options_ended=false skip_next=false

  for arg in "$@"; do
    if $skip_next; then
      skip_next=false
      continue
    fi
    if $destination_seen; then
      return 0
    fi
    if $options_ended; then
      destination_seen=true
      continue
    fi

    case "$arg" in
      --) options_ended=true ;;
      -[BbcDEeFIiJLlmOoPpQRSWw]) skip_next=true ;;
      -*) ;;
      *) destination_seen=true ;;
    esac
  done

  return 1
}

ssh() {
  emulate -L zsh
  setopt local_options no_glob_subst

  local ssh_term="xterm-256color"
  local -a ssh_opts
  ssh_opts=(
    -o "SetEnv COLORTERM=truecolor"
    -o "SendEnv TERM_PROGRAM TERM_PROGRAM_VERSION"
  )

  local ssh_key ssh_value ssh_user ssh_hostname ssh_remote_command
  while IFS=' ' read -r ssh_key ssh_value; do
    case "$ssh_key" in
      user) ssh_user="$ssh_value" ;;
      hostname) ssh_hostname="$ssh_value" ;;
      remotecommand) ssh_remote_command="$ssh_value" ;;
    esac
  done < <(command ssh -G "$@" 2>/dev/null)

  if [[ -n "$ssh_hostname" ]]; then
    local ssh_target="${ssh_user}@${ssh_hostname}"
    local ghostty_bin="$GHOSTTY_BIN_DIR/ghostty"

    if [[ -x "$ghostty_bin" ]] && "$ghostty_bin" +ssh-cache --host="$ssh_target" >/dev/null 2>&1; then
      ssh_term="xterm-ghostty"
    # OpenSSH joins everything after the destination into one remote command.
    # Appending the installer to an existing command could execute that command
    # during setup and then execute it again in the final session. A configured
    # RemoteCommand has the same conflict, so only install for login sessions.
    elif [[ -z "$ssh_remote_command" ]] && ! _ssh_has_remote_command "$@" && (( $+commands[infocmp] )); then
      local ssh_terminfo ssh_cpath_dir ssh_cpath
      ssh_terminfo=$(infocmp -0 -x xterm-ghostty 2>/dev/null)

      if [[ -n "$ssh_terminfo" ]]; then
        print "Setting up xterm-ghostty terminfo on $ssh_hostname..." >&2

        ssh_cpath_dir=$(mktemp -d "${TMPDIR:-/tmp}/ghostty-ssh-$ssh_user.XXXXXX" 2>/dev/null) || \
          ssh_cpath_dir="${TMPDIR:-/tmp}/ghostty-ssh-$ssh_user.$$"
        ssh_cpath="$ssh_cpath_dir/socket"

        if builtin print -r "$ssh_terminfo" | command ssh "${ssh_opts[@]}" \
          -o ControlMaster=yes -o ControlPath="$ssh_cpath" -o ControlPersist=60s "$@" '
            infocmp xterm-ghostty >/dev/null 2>&1 && exit 0
            command -v tic >/dev/null 2>&1 || exit 1
            mkdir -p ~/.terminfo 2>/dev/null && tic -x - 2>/dev/null && exit 0
            exit 1
          ' 2>/dev/null; then
          ssh_term="xterm-ghostty"
          ssh_opts+=(-o "ControlPath=$ssh_cpath")
          [[ -x "$ghostty_bin" ]] && "$ghostty_bin" +ssh-cache --add="$ssh_target" >/dev/null 2>&1 || true
        else
          print "Warning: Failed to install terminfo." >&2
        fi
      else
        print "Warning: Could not generate terminfo data." >&2
      fi
    fi
  fi

  local host ssh_client=tssh
  host="$(_ssh_extract_host "$@")"
  (( $+commands[tssh] )) || ssh_client=ssh

  if [[ -z "$host" ]]; then
    TERM="$ssh_term" command "$ssh_client" "${ssh_opts[@]}" "$@"
    return
  fi

  TERM="$ssh_term" _tinted_ssh "$ssh_client" '#221e1e' "🔥 $host" "${ssh_opts[@]}" "$@"
}
