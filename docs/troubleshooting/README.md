# Troubleshooting notes

Short, topic-based records of problems, their causes, and verified solutions.
These guidelines apply to troubleshooting notes, not all documentation under
`docs/`.

## Adding a troubleshooting note

1. Create `docs/troubleshooting/<topic>.md` with a descriptive, lowercase, hyphenated name. Name it
   after what someone would look up, such as `terminal-keyboard`, rather than a
   session, date, or issue number.
2. Keep one problem area in one document, even when it spans multiple applications
   or packages.
3. Keep brief explanations beside non-obvious configuration settings. Link to the
   document from there when more context would help. Keep documentation outside
   Stow packages under `config/` so it is not installed as application configuration.
4. Check snippets and relative links against the actual files, then run
   `git diff --check`. Record what was verified; do not imply that one machine's
   result guarantees behavior on other versions or platforms.

Aim for a one-pager. A compact investigation table is useful when the failed
approaches explain why the final solution is necessary; a conversation transcript
is not. Prefer this structure, omitting sections that add no value:

```markdown
# Topic

## Working solution
Summary, links to authoritative configuration files, and essential snippets.

## What was happening
Symptoms, established causes, and relevant environment/version details.

## Approaches and results
Only useful experiments. Distinguish observations from hypotheses and note
when multiple changes or leftover runtime state prevented a clean comparison.

## Apply and verify
Reload steps, a short manual check, and useful diagnostics.

## References
Relevant upstream documentation, with version caveats where needed.
```

## Maintaining notes

- Treat configuration files as the source of truth. Link to them instead of
  copying entire files; keep any small excerpts synchronized when settings change.
- Update the relevant note in the same change as the configuration it explains.
- Put the current solution first. Label historical experiments so they are not
  mistaken for instructions to apply today.
- Explain what a workaround compensates for and when it might be removable.
  Do not describe a local workaround as an upstream recommendation.
- Keep credentials and private diagnostic output out of documentation.
- Use Git history for the full change history; keep these pages focused on useful
  explanations, decisions, and verification.
