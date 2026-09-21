# Terminal keyboard behavior

Verified interactively on macOS with Ghostty 1.3.1 and tmux 3.7c (reported versions),
using zsh and AI CLIs including Codex. This is a working configuration for this
setup, not a universal requirement for every terminal or application.

## Working solution

**Explicit zsh vi editing with navigation bindings, plus a tmux-only Shift+Enter
binding. No Ghostty Shift+Enter override is needed in the verified setup.**

- [Shell configuration](../../config/shared/shell/.config/shell/interactive.zsh):

  ```zsh
  bindkey -v
  bindkey -M viins '^[b' backward-word
  bindkey -M viins '^[f' forward-word
  bindkey -M viins '^A' beginning-of-line
  bindkey -M viins '^E' end-of-line
  ```

  This preserves vi command/insert modes while making Option+Left/Right move by
  word and Cmd+Left/Right move to the beginning/end of the line in insert mode.
  Esc enters command mode; `i` returns to insert mode. For emacs-style editing,
  replace this block with `bindkey -e`: its default keymap already provides these
  four bindings. Explicit `-M emacs` bindings are needed only if something has
  changed those defaults.

- [tmux configuration](../../config/shared/tmux/.config/tmux/tmux.conf):

  ```tmux
  set -s extended-keys on
  bind -n S-Enter send-keys -l "\e[13;2u"
  ```

  Applications can request extended reporting normally. The binding forwards
  Shift+Enter as literal CSI-u bytes even without a successful application request.
  `-n` means no tmux prefix is needed. The receiving application decides whether
  Shift+Enter inserts a newline.

- [Ghostty configuration](../../config/shared/ghostty/.config/ghostty/config.ghostty):
  no custom Shift+Enter binding. The macOS `platform.conf` sets
  `macos-option-as-alt = left`; Ghostty's existing Option-arrow and Cmd-arrow
  behavior supplies the sequences bound above.

## What was happening

### Shell navigation: different editing modes

At startup, zsh chooses vi editing when the relevant inherited `VISUAL`/`EDITOR`
value contains `vi` (`VISUAL` takes precedence). An inherited `EDITOR=nvim` therefore
can select vi mode. Setting the variable later in `.zshrc` does not itself change
the already-selected keymap. Shells launched inside tmux can inherit that variable
even when the original terminal shell did not.

We reproduced `main` linked to `viins` with inherited `EDITOR=nvim`, and to `emacs`
without inherited editor variables. In vi insert mode, Meta-b/f were undefined;
in emacs mode, they were already backward/forward-word.

Ghostty sends Escape+b/f for Option+Left/Right. With no matching insert-mode
bindings, Escape can enter vi command mode: `b` moves backward, but `f` waits for a
character to find. Subsequent typing can become editing commands. This explains
why backward navigation appeared to work while forward navigation led to strange
cursor movement and deleted/overwritten text. Binding both sequences fixed it.

Explicitly selecting vi mode then exposed the same missing bindings outside tmux:
Cmd+Left/Right produced `^A`/`^E` rather than navigating. Binding Ctrl+A/E to
beginning/end-of-line fixed that too. These were shell keymap issues, not a reason
to disable extended keys globally.

### Shift+Enter: two stages of keyboard handling

Input travels through `Ghostty → tmux → application`. tmux decodes keys and
re-encodes them for the pane; it is not a transparent byte pipe. Distinct input at
the first stage does not guarantee distinct output at the second.

Automatic reporting alone still failed to insert a newline in Codex. A Ghostty-only
override also failed. The tmux forwarding binding worked, and continued to work
after removing the Ghostty override. This establishes the useful workaround;
it does not by itself prove the exact protocol request made by each application.

## Approaches and results

Earlier experiments changed several settings and sometimes retained runtime state.
Their reported symptoms should not be treated as isolated tests of each option.

| Approach tried | Observed result / lesson |
| --- | --- |
| Ghostty Shift+Enter → `text:\x1b\r` | Used Escape+Return, conventionally Alt+Enter, rather than a distinct Shift+Enter encoding. Escape-related cancellation was reported. The initial claim that this caused all the word-navigation problems was not established. |
| tmux `extended-keys on` with an `extkeys` feature override | Reported to fix Shift+Enter in one CLI but not Codex. Application opt-in alone was insufficient for all tested CLIs. |
| tmux `extended-keys always`, `csi-u`, and `extkeys` | Shift+Enter worked in Codex; Option navigation and window-switching problems were reported. The later zsh diagnosis means these symptoms do not establish that extended keys caused the navigation issue. |
| Ghostty Shift+Enter → bare LF (`text:\n`) | Did not fix Shift+Enter. LF is Ctrl+J, which `vim-tmux-navigator` binds for pane navigation. |
| Revert tmux configuration and reload | Problems persisted. Inspection found live extended-key settings and repeated `extkeys` entries still present; deleting configuration lines had not undone them. |
| Ghostty CSI-u override plus tmux explicit forwarding, with extended keys off | Shift+Enter and window switching worked. Word navigation remained broken until the zsh insert-mode bindings were added. |
| Fix zsh word bindings; then try automatic reporting with `extended-keys on` and no Shift+Enter overrides | Navigation and window switching worked; Codex Shift+Enter still failed. |
| Ghostty CSI-u override only, with tmux `extended-keys on` | Codex Shift+Enter still failed. |
| Both explicit Shift+Enter bindings | Working fallback, but did not establish that both were necessary. |
| Remove Ghostty override, keep tmux forwarding and `extended-keys on` | User confirmed everything worked. This is the final, narrower configuration. |
| Explicit `bindkey -v`, then add Ctrl+A/E bindings | Made vi editing consistent inside/outside tmux and fixed Cmd-arrow line navigation in insert mode. |

### Settings that are easy to confuse

- `\x1b[13;2u` / `\e[13;2u` encodes Shift+Enter in CSI-u: key 13, modifier 2.
  Ghostty's `csi:13;2u` sends the same bytes. These were tested overrides, not
  instructions to add a Ghostty binding to the final setup.
- `\x1b\r` is Escape+Return, not a Shift+Enter encoding. Both forms contain an
  Escape byte; recognizing the complete sequence is what matters.
- tmux `extended-keys on` allows applications to request extended reporting.
  `off` disables normal extended reporting to applications. `always` forces mode 1
  even without an application request; mode 1 extends keys lacking a conventional
  distinct representation, while mode 2 changes reporting more broadly.
- `extended-keys-format` selects the encoding of tmux's normal extended output.
  Our literal `send-keys -l` binding supplies its own bytes independently.
- `terminal-features ...:extkeys` describes outer-terminal capability. It is
  separate from application-side reporting and does not mean full Kitty keyboard
  protocol support. A blanket feature override is not part of this solution.
- Modern tmux documentation describes extended-key support as enabled by default,
  but resetting the option in this session yielded `off`. We set `on` explicitly
  and check the live value rather than depending on an assumed default.

## Apply and verify

Load shell changes in each existing zsh, and reload tmux configuration:

```sh
source ~/.config/shell/interactive.zsh
tmux source-file ~/.config/tmux/tmux.conf
```

For Ghostty changes, use Reload Configuration (Cmd+Shift+, on this setup).
After changing terminal capability/negotiation settings, detach and reattach tmux
and start a fresh CLI instance. Detaching preserves running programs.

**Reloading tmux configuration is additive, not a reset.** When removing an
experimental binding, explicitly unbind it, for example
`tmux unbind-key -n S-Enter`. Removed options must also be explicitly restored to
their intended values. Do not run that unbind command as part of the working setup.

Useful read-only checks:

```sh
bindkey -lL main
bindkey -M viins '^[b'
bindkey -M viins '^[f'
bindkey -M viins '^A'
bindkey -M viins '^E'
tmux show-options -s extended-keys
tmux show-options -s terminal-features
tmux list-keys -T root
tmux list-clients -F '#{client_name}: #{client_termfeatures}'
```

Manual verification, both inside and outside tmux where applicable:

1. At a fresh zsh prompt in insert mode, type `one two three` without submitting.
   Option+Left/Right should move by word; typing afterward should insert normally.
2. Cmd+Left/Right should move to the beginning/end of the line without inserting
   control characters. Esc then `i` should still switch vi modes normally.
3. In a tmux session with two windows, Option+Shift+H/L should switch windows.
4. In the AI CLIs, Shift+Enter should add a newline and ordinary Enter should keep
   its normal submit behavior. Test the actual applications, not just a byte reader.

Change one layer at a time when retesting. The tmux-only override is the verified
minimum here, not a claim that all versions or terminals require it.

## References

- Installed `man tmux`: `extended-keys`, `extended-keys-format`, `terminal-features`,
  and `send-keys` (prefer the installed version's descriptions).
- [tmux modifier keys](https://github.com/tmux/tmux/wiki/Modifier-Keys) (includes a
  warning that parts of the page predate tmux 3.5).
- [Ghostty keybinding actions](https://ghostty.org/docs/config/keybind/reference).
- [zsh keymaps](https://zsh.sourceforge.io/Doc/Release/Zsh-Line-Editor.html#Keymaps).
