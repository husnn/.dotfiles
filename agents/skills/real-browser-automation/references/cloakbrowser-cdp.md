# CloakBrowser over CDP

Use the configured CDP URL, defaulting to `http://127.0.0.1:9222` only when none was supplied. Probe its `/json/version` endpoint and preserve the returned WebSocket URL when a client requires it. Reuse an existing relevant page and authenticated context instead of launching another profile.

Treat the agent host and browser host as separate. On a remote Linux agent, the CDP URL will commonly be an SSH tunnel or proxy to the visible CloakBrowser running on the user's Mac; do not try to launch a GUI browser on that Linux host. When the agent is running on the Mac, it may connect directly to the existing browser and use the local CloakBrowser installation when a browser must be started.

For deterministic Node.js automation, use pnpm and Playwright. Apply CloakBrowser's humanized-input patch before interacting when that behavior is required:

```js
import { chromium } from "playwright-core";
import { patchBrowser, resolveConfig } from "cloakbrowser/human";

const browser = await chromium.connectOverCDP(
  process.env.CDP_URL ?? "http://127.0.0.1:9222"
);
patchBrowser(browser, resolveConfig("default"));

const pages = browser.contexts().flatMap((context) => context.pages());
const page = pages.at(-1);
if (!page) throw new Error("No existing browser page is available");
```

Use stable CSS, text, label, placeholder, title, alt-text, or test-id selectors. If the humanized wrapper rejects a complex selector, translate it to a stable supported selector. CloakBrowser reduces common fingerprint and behavioral signals but cannot guarantee that automation is undetectable.

Before a consequential retry, confirm whether the intended action already exists. Verify the target with relevant identifiers and confirm the resulting rendered state. Disconnecting a CDP client normally leaves the persistent CloakBrowser process running.

Official reference:

- <https://github.com/CloakHQ/CloakBrowser>
