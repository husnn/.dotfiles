# CloakBrowser CDP support project

This private support project launches a visible CloakBrowser with its Chrome
DevTools Protocol endpoint bound to loopback. The user-facing command is
`scripts/cloak-cdp`, which also opens the reverse SSH tunnel and supervises both
processes.

Run the combined service from any interactive shell:

```sh
cloak-cdp
```

By default, local `127.0.0.1:9222` is exposed as `127.0.0.1:9222` on
`hermes-vps`. Use `cloak-cdp --help` for port, host, and headless options. The
remote endpoint remains bound to loopback; press Ctrl-C in the local shell to
close both the tunnel and browser.

The Python version is pinned in `.python-version`, dependencies are declared in
`pyproject.toml`, and exact versions are recorded in `uv.lock`. `uv run --frozen`
creates/restores the ignored virtual environment on first use.
