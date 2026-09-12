---
name: git-commit-message
description: Write, review, or refine Git commit messages from the actual changes and repository conventions. Use when proposing a commit message, creating a commit, amending commit wording, or deciding whether staged changes form a coherent commit. Do not use for work that does not involve a Git commit.
---

# Git Commit Messages

Write a message that lets a reader understand the purpose and scope of the commit without opening the diff. Describe what the commit accomplishes, not the activity of editing files.

## Establish the scope

- Inspect the complete staged diff, including new files, deletions, generated files, and dependency updates.
- Read recent commit subjects and repository-specific contribution guidance.
- Describe only changes that are actually staged. Preserve intentional staging and do not silently add unrelated working-tree changes.
- Check that the staged changes serve one coherent purpose. If they do not, propose separate commits rather than hiding unrelated work behind a broad subject.

## Write the subject

- Summarize the whole commit in one concise, natural sentence fragment.
- Use a precise, present-tense imperative verb such as `Add`, `Fix`, `Prevent`, `Remove`, or `Migrate`.
- State the meaningful outcome rather than the files or implementation activity.
- Be specific enough to distinguish the change from nearby work and broad enough to cover every material part of the commit.
- Keep context implicit when the repository already makes it obvious.
- Avoid vague, robotic, inflated, or redundant wording.
- Follow an established scope or conventional-commit format when the repository consistently uses one; do not force or invent one.
- Do not end the subject with a period.

## Decide whether to add a body

Omit the body when the subject fully explains a focused change. Add one when the commit has several meaningful parts, non-obvious motivation, surprising behavior, or migration consequences.

When a body is useful:

- Explain why the change was needed, what behavior changed, and important consequences not clear from the subject.
- Use separate bullets for distinct changes when that improves readability.
- Keep independent changes in separate bullets.
- Focus on outcomes and decisions, not filenames, line edits, rearrangements, or other incidental mechanics.
- Do not merely repeat the subject or enumerate details that add no context.

Make every claim verifiable from the staged diff. Mention tests, generated artifacts, dependency updates, or migrations only when they materially help explain the commit. Never add author attribution, AI attribution, co-author trailers, or unrelated metadata.

When the wording is uncertain or the user is refining it, present the complete proposed message before committing. After creating or amending a commit, inspect the rendered message for quoting or newline errors and verify the working tree state.

For examples and common failure modes, read [examples.md](references/examples.md) when examples would help resolve wording, scope, or body structure.
