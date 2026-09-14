# Browser Use

Read this reference after selecting a locally executed Browser Use agent as the
control method. Browser Use supplies reasoning; the selected browser supplies
the session over CDP, usually the existing CloakBrowser. This reference does not
apply to deterministic Playwright/CDP automation or a provider's hosted agent.

The skill's reusable runner is mandatory for local Browser Use tasks that
may request input or handoff. It keeps one agent and browser session alive while
the originating harness relays replies. Do not write an ad-hoc runner or run
competing agents in the same tab.

## Reusable runner

Use `scripts/browser_use_runner.py` in this skill. Inline UV dependency metadata
avoids creating and deleting a project for every reply. This is the required
path, not an example to reimplement. Do not create a disposable UV project or
invoke Agent directly in a replacement script for an input-capable task. Allocate
the private task directory required by SKILL.md, retain its exact returned path,
and write the full task, constraints, established authorization, and success
evidence to `task.txt` directly inside it. Do not put the prompt directly in `/tmp`.

For example, first allocate the directory:

```sh
mktemp -d /tmp/real-browser-automation.XXXXXX
```

Write `task.txt` using the harness's file-editing tool, then launch with the actual
returned path (the suffix below is illustrative):

```sh
uv run /path/to/real-browser-automation/scripts/browser_use_runner.py --task-file /tmp/real-browser-automation.aB12cd/task.txt
```

Resolve paths for this installation. The runner uses `CDP_URL` or
`http://127.0.0.1:9222`, `gpt-5.6-terra`, finite step/failure limits, and native
loop detection. Code and cached dependencies remain reusable.

The originating agent owns the outer task directory and its prompt. The runner
creates a private `artifacts.<random>/` directory inside the prompt's parent and
removes only that nested directory through its context manager. The runner does
not delete the supplied task file or its parent. This separates cleanup ownership
while keeping both prompt and runner-managed artifacts under one task directory.

Retain the outer directory path alongside the process handle and pending request.
Once the runner exits, the originating agent removes that exact outer directory,
including the prompt. Also clean it up if launch fails. If input waiting ends in
a live process, retain it; if the process exits into recovery, keep the minimal
checkpoint in the conversation and clean up the old directory before a new run.
Move requested deliverables before the runner's artifact cleanup. Do not attach
an EXIT trap to a short-lived launcher that could delete files while its background
runner is still active; cleanup must follow the actual runner lifecycle.

Use `gpt-5.6-terra` exactly and report model-access failures instead of substituting
another model. Configure native loop detection, a finite `max_steps`, and the
failure limit through the runner. Do not supervise its browser actions step by
step with another model; observe output for input events and completion.

Launch with stdin open in a persistent process. In Codex, use `exec_command` with
`tty: true`, retain its returned `session_id`, and use `write_stdin` for replies.
A `functions.exec` cell ID is not that process ID. Use permissions required by the
browser/network and verify stdin in the actual execution environment. Ending a
conversation turn must not intentionally terminate the runner. Do not delete the
task directory or create a replacement project while it is waiting. If the harness
cannot preserve it, use the fallback below.

Other originating harnesses should use their equivalent persistent-process
launch, output wait/poll, and stdin-write operations. Preserve the same process
handle across replies; Codex tool names are not requirements for other harnesses.

## Origin-owned input protocol

Single-line JSON events prefixed with `BRIDGE ` appear alongside agent logs.
The harness relays questions; the runner never selects a chat or recipient.

```json
{"type":"needs_input","id":"unique-id","question":"What value is required?"}
{"type":"browser_handoff","id":"unique-id","question":"Complete the displayed step, then reply done.","session_reference":"CloakBrowser, tab ABC, relevant URL"}
```

Send one JSON line to the same process's stdin:

```json
{"id":"unique-id","answer":"user's actual reply"}
```

Only a nonempty answer with the matching ID resumes the tool. Correlate the
conversation and process as well as the ID. Never supply a default answer or
infer completion from elapsed time. A matching `{"id":"...","cancel":true}` ends
the run gracefully. Never interpolate replies into shell commands. PTY input
echo is disabled; agent logs can still contain task data, so do not persist full
logs by default.

For questions, `request_user_input` returns the answer to the same agent.
For handoff, `request_browser_handoff` waits while the user controls the browser.
Confirm availability separately if needed; agreement to start is not completion.
After a reply, inspect the page before acting. The generic runner does not poll
the browser during handoff. Optional polling belongs in a task-specific adapter
with a known completion predicate and user agreement to automatic resumption.
It must not click, type, or submit while the user is active.

The default input deadline is one hour (`--input-timeout` overrides it); the stepcleanup
timeout exceeds it. Timeout, EOF, and cancellation end the run without assuming
an answer. A `paused` event includes the pending request for fallback. Temporary
artifacts are removed on exit; `session.stop()` disconnects without killing
CloakBrowser. This is not a durable background service or protection against
host termination.

## Reconnect fallback

Use this fallback only when the process has exited (including input timeout) or
the harness demonstrably cannot retain it. Record the reason; preferring a fresh
project is not a fallback condition. Keep a minimal checkpoint in
the originating conversation: task and constraints, established permissions,
verified progress, pending request, and relevant tab/session reference. Do not
export authenticated HTML, cookies, or full histories merely to resume.

After the reply, invoke the same script with the checkpoint and answer included
in its task. Reconnect and inspect the page. Check whether a consequential action
already succeeded before repeating it. This is a new agent against the persistent
browser, not restoration of its old Python state. Rebuilding a dependency project
adds no benefit.

An uncatchable termination can leave the outer directory and nested artifacts.
Clean up only the verified, inactive directory owned by this task, never broad
temporary-directory patterns. A live input or handoff wait is not a cleanup boundary.

## Validation and adaptation

Run the stdlib-only `scripts/test_browser_use_runner.py` to exercise question and
handoff correlation, invalid replies, timeout, EOF, and cancellation without a
browser or API call. A live task is still needed to verify browser/model access.
The DVLA prototype verified two question/reply pauses in one agent; automatic
handoff detection is not implemented or implied by that test.

On hosts without POSIX stdin support, adapt the transport to supported IPC,
preserving correlation and pause semantics. Prefer known deterministic
Playwright/CDP flows when appropriate, per the skill's routing.

Official references:

- https://docs.browser-use.com/open-source/customize/tools/add
- https://github.com/CloakHQ/CloakBrowser/blob/main/examples/integrations/browser_use_example.py
