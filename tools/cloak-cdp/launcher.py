#!/usr/bin/env python
"""Run a local, headed CloakBrowser with a loopback-only CDP endpoint."""

from __future__ import annotations

import argparse
import asyncio
import contextlib
import signal
import sys
from typing import Any

from cloakbrowser import launch_async


READINESS_TIMEOUT = 10.0
READINESS_STABILITY = 2.0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=9222, help="loopback CDP port")
    parser.add_argument(
        "--headless",
        action="store_true",
        help="run without a visible browser window (useful for diagnostics)",
    )
    return parser.parse_args()


async def cdp_is_reachable(port: int) -> bool:
    """Return whether Chromium's loopback CDP endpoint answers an HTTP request."""
    writer: asyncio.StreamWriter | None = None
    try:
        reader, writer = await asyncio.wait_for(
            asyncio.open_connection("127.0.0.1", port), timeout=0.5
        )
        writer.write(
            b"GET /json/version HTTP/1.1\r\n"
            b"Host: 127.0.0.1\r\n"
            b"Connection: close\r\n\r\n"
        )
        await writer.drain()
        status_line = await asyncio.wait_for(reader.readline(), timeout=0.5)
        return status_line.startswith((b"HTTP/1.0 200", b"HTTP/1.1 200"))
    except (OSError, TimeoutError):
        return False
    finally:
        if writer is not None:
            writer.close()
            with contextlib.suppress(Exception):
                await writer.wait_closed()


async def raise_browser_exit(browser: Any) -> None:
    """Make CloakBrowser translate a post-handshake license denial for us."""
    try:
        await browser.new_context()
    except Exception as exc:
        if "CloakBrowser Pro:" in str(exc):
            raise
        raise RuntimeError("browser exited before its CDP endpoint became ready") from exc
    raise RuntimeError("browser disconnected before its CDP endpoint became ready")


async def wait_until_ready(browser: Any, port: int) -> None:
    """Require a stable CDP listener and a successful Playwright operation."""
    loop = asyncio.get_running_loop()
    deadline = loop.time() + READINESS_TIMEOUT
    reachable_since: float | None = None

    while loop.time() < deadline:
        if not browser.is_connected():
            await raise_browser_exit(browser)

        if await cdp_is_reachable(port):
            if reachable_since is None:
                reachable_since = loop.time()
            elif loop.time() - reachable_since >= READINESS_STABILITY:
                # CloakBrowser's license denial can arrive just after Playwright's
                # launch handshake. A guarded API call surfaces its specific error.
                context = await browser.new_context()
                await context.close()
                if browser.is_connected() and await cdp_is_reachable(port):
                    return
        else:
            reachable_since = None

        await asyncio.sleep(0.1)

    if not browser.is_connected():
        await raise_browser_exit(browser)
    raise RuntimeError(
        f"CDP endpoint did not become ready on http://127.0.0.1:{port} "
        f"within {READINESS_TIMEOUT:g} seconds"
    )


async def run() -> None:
    args = parse_args()
    if not 1 <= args.port <= 65535:
        raise SystemExit("--port must be between 1 and 65535")

    browser = await launch_async(
        headless=args.headless,
        args=[
            f"--remote-debugging-port={args.port}",
            "--remote-debugging-address=127.0.0.1",
        ],
    )
    disconnected = asyncio.Event()
    browser.on("disconnected", lambda _: disconnected.set())

    try:
        await wait_until_ready(browser, args.port)

        stop = asyncio.Event()
        loop = asyncio.get_running_loop()
        for sig in (signal.SIGINT, signal.SIGTERM):
            with contextlib.suppress(NotImplementedError):
                loop.add_signal_handler(sig, stop.set)

        mode = "headless" if args.headless else "headed"
        print(f"CloakBrowser is ready ({mode}).", flush=True)
        print(f"CDP endpoint: http://127.0.0.1:{args.port}", flush=True)

        stop_task = asyncio.create_task(stop.wait())
        disconnected_task = asyncio.create_task(disconnected.wait())
        try:
            await asyncio.wait(
                (stop_task, disconnected_task),
                return_when=asyncio.FIRST_COMPLETED,
            )
            if disconnected.is_set() and not stop.is_set():
                await raise_browser_exit(browser)
        finally:
            stop_task.cancel()
            disconnected_task.cancel()
            await asyncio.gather(stop_task, disconnected_task, return_exceptions=True)
    finally:
        with contextlib.suppress(Exception):
            await browser.close()


def main() -> None:
    try:
        asyncio.run(run())
    except KeyboardInterrupt:
        pass
    except Exception as exc:
        print(f"cloak-cdp: {exc}", file=sys.stderr)
        raise SystemExit(1) from None


if __name__ == "__main__":
    main()
