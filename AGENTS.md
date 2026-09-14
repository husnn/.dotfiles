# Project instructions

## Git commit messages

- When a commit affects only one area of the project, prefix its subject with that scope followed by a colon. Use the relevant top-level folder name or a specific filename, whichever describes the change most naturally.
- Omit the prefix when a commit spans multiple areas and no single scope accurately represents the whole change.

## Python

- Use UV for a Python project or any script with third-party dependencies: `uv init`, `uv add`, and `uv run`. UV keeps dependencies isolated and locked, and avoids modifying Homebrew's externally managed Python installation.
- Use `uvx` for a standalone Python CLI that should not become a project dependency.
- Use `python` directly only for short standard-library-only scripts or commands. On macOS, treat the global interpreter as Homebrew-managed and do not install packages into it with `pip`.
- Follow the existing environment and package manager in an established Python project.
