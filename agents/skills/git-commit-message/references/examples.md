# Commit message examples

## Focused changes

Small changes usually need only a subject:

```text
Prevent duplicate invoice charges during webhook retries
```

```text
Keep the selected conversation visible after reconnecting
```

```text
Document the recovery procedure for a regional outage
```

```text
Remove expired feature flags from checkout
```

## Changes that benefit from a body

Use the body to show how several details contribute to one outcome:

```text
Move session storage to Redis

- Share authenticated sessions across application instances.
- Preserve existing session expiry behavior.
- Add migration checks for deployments with active sessions.
```

```text
Add offline map downloads

- Cache selected regions for use without a network connection.
- Show download progress and storage usage.
- Resume interrupted downloads instead of starting over.
```

```text
Upgrade the syntax parsing stack

- Update the parser and language grammars together.
- Regenerate syntax snapshots for the new parse trees.
- Remove compatibility code for the previous parser API.
```

## Outcome-oriented wording

Prefer an outcome over a description of editing activity:

```text
Bad:  Update validation logic
Good: Reject reservations that overlap a venue closure
```

```text
Bad:  Change cache files and tests
Good: Invalidate product caches when regional prices change
```

```text
Bad:  Refactor authentication and improve security
Good: Rotate signing keys without invalidating active sessions
```

Avoid redundant subjects where a broad phrase repeats the specific change:

```text
Bad:  Switch to a new renderer and refresh graphics infrastructure
Good: Replace the legacy renderer
```

## Choose detail to fit the change

For a user-facing fix, make the broken behavior understandable without the debugging
conversation. A mechanism alone can leave the purpose implicit:

```text
Too implementation-focused: Forward Shift+Enter as CSI-u and bind viins Meta keys
Behavior-first: Fix terminal shortcuts for newlines and cursor navigation
```

A body can explain distinct results in plain bullets:

```text
Fix terminal shortcuts for newlines and cursor navigation

- Make Shift+Enter insert a newline in AI CLIs inside tmux instead of
  submitting the prompt.
- Fix Option+Right editing text unexpectedly instead of moving forward
  by a word.
- Make Cmd+Left and Cmd+Right jump to the beginning and end of the line
  instead of inserting control characters.
```

Technical detail is useful when it explains an important choice. It can accompany
the outcome rather than replace it:

```text
Preserve Shift+Enter for applications inside tmux

- Keep newline insertion working when an application does not request
  extended keyboard reporting by explicitly forwarding CSI-u Shift+Enter.
- Leave other extended keys application-controlled rather than forcing
  extended reporting for every application.
```

For a low-level change, technical wording may be the clearest explanation from
the outset:

```text
Use compare-and-swap to prevent lost concurrent cache updates
```

These are context-dependent choices, not a rule to avoid technical terminology.

## Incoherent scope

Do not force unrelated work into one vague message:

```text
Bad: Update dependencies, dashboard styles, and backup scripts
```

Split that work into separate commits unless the changes jointly deliver one clearly stated outcome.
