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

## Incoherent scope

Do not force unrelated work into one vague message:

```text
Bad: Update dependencies, dashboard styles, and backup scripts
```

Split that work into separate commits unless the changes jointly deliver one clearly stated outcome.
