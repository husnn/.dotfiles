# CloakBrowser CDP support project

This private support project launches a visible, persistent CloakBrowser with
its Chrome DevTools Protocol endpoint bound to loopback. The user-facing command
is `scripts/cloak-cdp`, which also opens the reverse SSH tunnel and supervises
both processes.

Run the combined service from any interactive shell:

```sh
cloak-cdp
```

By default, local `127.0.0.1:9222` is exposed as `127.0.0.1:9222` on
`hermes-vps`. Use `cloak-cdp --help` for port, host, and headless options. The
remote endpoint remains bound to loopback; press Ctrl-C in the local shell to
close both the tunnel and browser.

Persistent state uses the repository's XDG convention:

```text
${XDG_STATE_HOME:-$HOME/.local/state}/cloak-cdp/
├── profile/
└── fingerprint-seed
```

The profile preserves cookies, local storage, IndexedDB, cache, history, and
authenticated sessions between runs. On its first launch, the tool generates
`fingerprint-seed` with mode `0600`; every later launch reuses it. Keeping the
seed beside the Chromium profile preserves the browser identity independently
of the profile data. The launcher refuses to change a recorded seed, silently
assign a new fingerprint to a nonempty existing profile, or replace a missing
authenticated profile merely because its seed survived.

Use `--state-dir` or `CLOAK_CDP_STATE_DIR` to select another durable, absolute
state root with the same layout. Use `--fingerprint` or
`CLOAK_CDP_FINGERPRINT_SEED` only when initializing a new state root or recording
the known seed for an existing profile. Temporary directories are intentionally
unsupported for the default state root. Runtime state never belongs in the
dotfiles checkout.

The Python version is pinned in `.python-version`, dependencies are declared in
`pyproject.toml`, and exact versions are recorded in `uv.lock`. `uv run --frozen`
creates/restores the ignored virtual environment on first use.
