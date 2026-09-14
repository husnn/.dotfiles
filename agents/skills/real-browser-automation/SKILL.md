---
name: real-browser-automation
description: Browser automation for navigating pages, inspecting content, clicking, typing, scrolling, submitting forms, and completing interactive web workflows. Use whenever browser control would help, especially for authenticated sessions, personal accounts, dynamic web apps, visible or humanized interaction, or stealth-sensitive work. Choose an existing CloakBrowser session, a configured cloud browser, or simpler HTTP/API access according to the task.
---

# Real Browser Automation

Choose the route by what the task needs: existing authentication and browser state, rendered interaction, user visibility, fingerprint protection, isolation, or scale. Honor an explicitly requested route. Otherwise use the simplest suitable method; the availability of a local browser or reusable runner does not by itself determine the choice.

## Choose access and browser session

- **No browser needed:** Use an official API, direct HTTP, or web tools when they can complete the task reliably without rendered interaction or browser-only state. Public or read-only work is a common fit, but a read-only task may still need a browser.
- **Existing CloakBrowser:** Prefer the existing session when its login/profile state, continuity, visible user handoff, or fingerprint protection benefits the task. Reuse the relevant tab and context. Read [references/cloakbrowser-cdp.md](references/cloakbrowser-cdp.md) for connection and host details. The browser may be on the user's Mac while the agent connects through a tunnel.
- **Configured cloud browser:** Use Browserbase or Browser Use Cloud when isolation, disposable sessions, or scale are useful and the required access is available. Cloud can also be a fallback when local CDP is unreachable, but it does not inherit the user's local authentication. Do not silently replace a required authenticated session with an unauthenticated one or start an unrequested login flow.

CloakBrowser's fingerprint protection and humanized interaction can help on automation-sensitive sites; they do not guarantee access. Local authentication and browser stealth are reasons to select a session, not reasons to require a particular agent or programming language.

## Choose the control method

Choose this separately from the browser session:

- **Browser Use agent (local):** Suitable for unfamiliar, exploratory, or changing multi-step workflows that benefit from autonomous page interpretation. When running Browser Use locally against a CDP session, read [references/browser-use.md](references/browser-use.md) and use its reusable runner and input protocol. Those requirements apply after selecting this route; they do not mandate it for all browser tasks.
- **Playwright or direct CDP:** Suitable for known flows, stable selectors, repeatable automation, or precise individual interactions. These can use the same authenticated CloakBrowser session without a Browser Use agent. For CloakBrowser, use its supported humanized-input wrapper when humanized interaction is needed; see its connection reference.
- **Configured cloud controls:** Use the selected provider's available SDK, tools, or agent interface as appropriate. Follow that interface's session and input lifecycle rather than assuming the local runner protocol applies.

For Node.js dependencies, use pnpm. Read only the references for the selected route.

## Execute and verify

- Preserve the user's exact target, values, wording, scope, and navigation constraints.
- Prefer DOM and accessibility information; use vision when essential rendered information is otherwise unavailable.
- Stop before a sixth failed attempt at the same step; use at most three materially different approaches across routes. Stop on denied access or missing required authentication.
- Before retrying a consequential action, check whether it already succeeded. Verify the final rendered state or API response before reporting success.

## Decisions and user handoff

Be generally optimistic: make reasonable assumptions for clear, low-cost, readily reversible choices. Routine navigation, obvious defaults, and read-only continuation within the request do not need a question at every step. A site's confirmation screen does not itself require another question when the facts are already established.

Consult the user for even slightly confusing or risky decisions: ambiguous targets or meaning, alternatives that change the outcome, or assumptions with meaningful consequences. Ask for required facts that cannot be reliably inferred; do not invent identifiers, credentials, or authorization. Preserve prior confirmations.

Route questions and replies through the conversation that started the task. Preserve the active session while waiting where supported. For handoff, identify the browser/tab and requested interaction, establish availability if needed, and pause browser actions until the user confirms completion. Reinspect before continuing. Read-only polling is optional when the user accepts automatic resumption and a specific completion condition is known; a changed page alone is not general proof of completion.

## Artifacts and cleanup

For every route that creates local task files, first allocate a private, randomly named task directory under the system temporary directory (for example, `mktemp -d /tmp/real-browser-automation.XXXXXX`, mode 0700). Keep agent-created task prompts, scratch code, downloads, and temporary outputs inside that directory. Do not create loose or predictable files such as `/tmp/dvla-task.txt`. No directory is needed when the task creates no local files. Reusable code, dependency caches, and the user's persistent browser profile are separate from task storage.

The originating agent owns this directory: retain its exact path with the active task/process and arrange cleanup on completion, failure, cancellation, or an exited runner. Preserve it during live input and handoff waits. Before removing it, confirm its processes have ended and move requested deliverables into the workspace. Remove only that exact owned directory; after an interruption, verify ownership and that it is no longer in use before cleanup. Follow the selected route's reference for any nested workspace the tool manages itself.

Do not persist authenticated HTML, screenshots, histories, cookies, or credentials by default. Disconnect without closing the user's persistent browser; follow the selected route's lifecycle guidance.
