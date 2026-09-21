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

## Choose the reader's level of detail

- Assume the reader did not participate in the investigation. Lead with the purpose and outcome; for a behavior fix, explain what was broken and what now works before describing the mechanism.
- Do not make protocol names, internal settings, or configuration syntax carry the entire explanation. Connect them to the problem they solve when that connection is not obvious.
- Include technical detail when it explains an important decision, limitation, compatibility requirement, or tradeoff. Omit it when it merely lists implementation steps.
- Match the language to the change. User-facing fixes often benefit from behavior-first wording; refactors, API changes, build changes, and low-level fixes may need technical language from the outset.
- Different bullets can use different levels of detail. A mostly behavioral message can include a technical point when it materially improves understanding.

## Write the subject

- Summarize the whole commit in one concise, natural sentence fragment.
- Use a precise, present-tense imperative verb such as `Add`, `Fix`, `Prevent`, `Remove`, or `Migrate`.
- State the meaningful outcome rather than the files or implementation activity.
- For guidance or policies, name the activity they govern rather than the qualities they aim to encourage. Prefer "Add guidance for writing comments" over "Add guidance for clear, purpose-driven comments": the latter can sound like guidance for only a particular kind of comment, rather than instructions for writing comments generally.
- A straightforward action can already explain the purpose. Do not add words like "clear," "effective," or "robust" merely to make the subject sound outcome-oriented; include such qualities only when they identify a specific, supported change rather than an aspiration.
- Be specific enough to distinguish the change from nearby work and broad enough to cover every material part of the commit.
- Keep context implicit when the repository already makes it obvious.
- Avoid vague, robotic, inflated, or redundant wording.
- Follow an established scope or conventional-commit format when the repository consistently uses one; do not force or invent one.
- Do not end the subject with a period.

## Decide whether to add a body

Omit the body when the subject fully explains a focused change. Add one when the commit has several meaningful parts, non-obvious motivation, surprising behavior, or migration consequences.

When a body is useful:

- Explain why the change was needed, what behavior changed, and important consequences not clear from the subject.
- For several distinct outcomes, prefer plain bullets, each explaining one meaningful result. Do not force a bullet for every file or implementation step.
- Focus on outcomes and decisions, not filenames, line edits, rearrangements, or other incidental mechanics.
- Do not merely repeat the subject or enumerate details that add no context.
- Avoid describing the same outcome twice, once behaviorally and once technically, unless the technical explanation adds an important reason or consequence.

Make every claim verifiable from the staged diff. Mention tests, generated artifacts, dependency updates, or migrations only when they materially help explain the commit. Never add author attribution, AI attribution, co-author trailers, or unrelated metadata.

Before finalizing, ask: could someone reading this message without the conversation explain why the change was worth making?

When the wording is uncertain or the user is refining it, present the complete proposed message before committing. After creating or amending a commit, inspect the rendered message for quoting or newline errors and verify the working tree state.

For examples and common failure modes, read [examples.md](references/examples.md) when examples would help resolve wording, scope, or body structure.
