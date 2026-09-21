# Project instructions

## Git commit messages

- When a commit affects only one area of the project, prefix its subject with that scope followed by a colon. Use the relevant top-level folder name or a specific filename, whichever describes the change most naturally.
- Omit the prefix when a commit spans multiple areas and no single scope accurately represents the whole change.

## Code and configuration comments

- Write for someone who did not see the investigation. Explain why the setting or code exists: the behavior it enables or the problem it prevents, rather than paraphrasing the implementation.
- Supply the missing causal link. For example, do not just say "preserve modifier information"; explain that a terminal application may receive Enter and Shift+Enter identically, so it cannot give them different actions.
- Use concrete examples to connect an abstract mechanism to recognizable behavior, such as inserting a newline versus submitting a prompt. Label examples so they do not appear to be the feature's only purpose.
- Introduce technical terms through their practical meaning. Keep precise names when useful, but do not require the reader to already understand the mechanism being explained.
- Prefer enough explanation over forced brevity. A few short sentences are better than one compressed sentence that leaves the reader asking why. Simpler means less background knowledge is required, not necessarily fewer words or less technical detail.
- Explain exceptions beside the exception. When a general setting is followed by a special-case workaround, explain why the general setting is insufficient and what the workaround compensates for.
- Match the certainty of the evidence. Describe verified behavior and local compatibility needs without turning them into universal claims about an application or protocol.
- Keep the investigation elsewhere. Comments should explain the current choice; troubleshooting documents can record experiments, alternatives, and results.

## Python

- Use UV for a Python project or any script with third-party dependencies: `uv init`, `uv add`, and `uv run`. UV keeps dependencies isolated and locked, and avoids modifying Homebrew's externally managed Python installation.
- Use `uvx` for a standalone Python CLI that should not become a project dependency.
- Use `python` directly only for short standard-library-only scripts or commands. On macOS, treat the global interpreter as Homebrew-managed and do not install packages into it with `pip`.
- Follow the existing environment and package manager in an established Python project.
