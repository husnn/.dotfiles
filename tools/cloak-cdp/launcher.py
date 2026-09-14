#!/usr/bin/env python
"""Run a persistent local CloakBrowser with a loopback-only CDP endpoint."""

from __future__ import annotations

import argparse
import asyncio
import contextlib
import os
import secrets
import signal
import sys
from pathlib import Path
from typing import Any

from cloakbrowser import launch_persistent_context_async


READINESS_TIMEOUT = 10.0
READINESS_STABILITY = 2.0
PROFILE_DIRNAME = "profile"
FINGERPRINT_FILENAME = "fingerprint-seed"
MIN_FINGERPRINT_SEED = 10000
MAX_FINGERPRINT_SEED = 99999


def fingerprint_seed(value: str) -> int:
    """Parse a CloakBrowser fingerprint seed in its documented default range."""
    try:
        seed = int(value)
    except ValueError as exc:
        raise argparse.ArgumentTypeError(
            "must be an integer from 10000 to 99999"
        ) from exc
    if not MIN_FINGERPRINT_SEED <= seed <= MAX_FINGERPRINT_SEED:
        raise argparse.ArgumentTypeError("must be an integer from 10000 to 99999")
    return seed


def absolute_dir(value: str) -> Path:
    """Require a durable, unambiguous directory location."""
    path = Path(value).expanduser()
    if not path.is_absolute():
        raise argparse.ArgumentTypeError("must be an absolute path")
    return path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=9222, help="loopback CDP port")
    try:
        xdg_state_home = absolute_dir(
            os.environ.get(
                "XDG_STATE_HOME", str(Path.home() / ".local" / "state")
            )
        )
        default_state_dir = absolute_dir(
            os.environ.get(
                "CLOAK_CDP_STATE_DIR", str(xdg_state_home / "cloak-cdp")
            )
        )
        fingerprint_default = os.environ.get("CLOAK_CDP_FINGERPRINT_SEED")
        default_fingerprint = (
            fingerprint_seed(fingerprint_default)
            if fingerprint_default is not None
            else None
        )
    except argparse.ArgumentTypeError as exc:
        parser.error(f"invalid CloakCDP environment configuration: {exc}")
    parser.add_argument(
        "--state-dir",
        type=absolute_dir,
        default=default_state_dir,
        help=(
            "durable state root containing the profile and fingerprint "
            "(or $CLOAK_CDP_STATE_DIR)"
        ),
    )
    parser.add_argument(
        "--fingerprint",
        type=fingerprint_seed,
        default=default_fingerprint,
        help=(
            "fixed seed used to initialize a new profile "
            "(or $CLOAK_CDP_FINGERPRINT_SEED)"
        ),
    )
    parser.add_argument(
        "--headless",
        action="store_true",
        help="run without a visible browser window (useful for diagnostics)",
    )
    return parser.parse_args()


def read_fingerprint(path: Path) -> int:
    try:
        return fingerprint_seed(path.read_text(encoding="utf-8").strip())
    except argparse.ArgumentTypeError as exc:
        raise RuntimeError(f"invalid fingerprint record at {path}: {exc}") from exc
    except OSError as exc:
        raise RuntimeError(
            f"could not read fingerprint record at {path}: {exc}"
        ) from exc


def resolve_profile_fingerprint(state_dir: Path, requested_seed: int | None) -> int:
    """Create or load the profile's immutable fingerprint record."""
    profile = state_dir / PROFILE_DIRNAME
    record = state_dir / FINGERPRINT_FILENAME
    if state_dir.exists() and not state_dir.is_dir():
        raise RuntimeError(f"state path is not a directory: {state_dir}")
    if profile.exists() and not profile.is_dir():
        raise RuntimeError(f"profile path is not a directory: {profile}")
    profile_exists = profile.exists()
    if record.exists() and not profile_exists:
        raise RuntimeError(
            f"fingerprint record exists at {record}, but profile {profile} is missing; "
            "refusing to create an unauthenticated replacement profile"
        )
    profile_had_data = profile_exists and any(profile.iterdir())
    try:
        state_dir.mkdir(mode=0o700, parents=True, exist_ok=True)
        profile.mkdir(mode=0o700, exist_ok=True)
        state_dir.chmod(0o700)
        profile.chmod(0o700)
    except OSError as exc:
        raise RuntimeError(
            f"could not initialize persistent browser state at {state_dir}: {exc}"
        ) from exc

    if record.exists():
        stored_seed = read_fingerprint(record)
        if requested_seed is not None and requested_seed != stored_seed:
            raise RuntimeError(
                f"state directory {state_dir} is bound to fingerprint {stored_seed}; "
                f"refusing requested fingerprint {requested_seed}"
            )
        return stored_seed

    if profile_had_data and requested_seed is None:
        raise RuntimeError(
            f"existing profile {profile} has no {FINGERPRINT_FILENAME} record; "
            "provide its known fingerprint with --fingerprint once"
        )

    seed = requested_seed or secrets.randbelow(
        MAX_FINGERPRINT_SEED - MIN_FINGERPRINT_SEED + 1
    ) + MIN_FINGERPRINT_SEED
    try:
        descriptor = os.open(record, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    except FileExistsError:
        stored_seed = read_fingerprint(record)
        if requested_seed is not None and requested_seed != stored_seed:
            raise RuntimeError(
                f"state directory {state_dir} was concurrently bound to fingerprint "
                f"{stored_seed}; "
                f"refusing requested fingerprint {requested_seed}"
            )
        return stored_seed
    except OSError as exc:
        raise RuntimeError(
            f"could not initialize persistent browser state at {state_dir}: {exc}"
        ) from exc

    with os.fdopen(descriptor, "w", encoding="utf-8") as fingerprint_file:
        fingerprint_file.write(f"{seed}\n")
        fingerprint_file.flush()
        os.fsync(fingerprint_file.fileno())
    return seed


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


async def raise_browser_exit(context: Any) -> None:
    """Make CloakBrowser translate a post-handshake license denial for us."""
    try:
        await context.new_page()
    except Exception as exc:
        if "CloakBrowser Pro:" in str(exc):
            raise
        raise RuntimeError(
            "browser exited before its CDP endpoint became ready"
        ) from exc
    raise RuntimeError("browser disconnected before its CDP endpoint became ready")


async def wait_until_ready(
    context: Any, closed: asyncio.Event, port: int
) -> None:
    """Require a stable CDP listener and a successful Playwright operation."""
    loop = asyncio.get_running_loop()
    deadline = loop.time() + READINESS_TIMEOUT
    reachable_since: float | None = None

    while loop.time() < deadline:
        if closed.is_set():
            await raise_browser_exit(context)

        if await cdp_is_reachable(port):
            if reachable_since is None:
                reachable_since = loop.time()
            elif loop.time() - reachable_since >= READINESS_STABILITY:
                # CloakBrowser's license denial can arrive just after Playwright's
                # launch handshake. A guarded page call surfaces its specific error
                # without creating a separate incognito browser context.
                page = context.pages[0] if context.pages else await context.new_page()
                await page.title()
                if not closed.is_set() and await cdp_is_reachable(port):
                    return
        else:
            reachable_since = None

        await asyncio.sleep(0.1)

    if closed.is_set():
        await raise_browser_exit(context)
    raise RuntimeError(
        f"CDP endpoint did not become ready on http://127.0.0.1:{port} "
        f"within {READINESS_TIMEOUT:g} seconds"
    )


async def run() -> None:
    args = parse_args()
    if not 1 <= args.port <= 65535:
        raise SystemExit("--port must be between 1 and 65535")

    profile = args.state_dir / PROFILE_DIRNAME
    seed = resolve_profile_fingerprint(args.state_dir, args.fingerprint)
    context = await launch_persistent_context_async(
        profile,
        headless=args.headless,
        args=[
            f"--fingerprint={seed}",
            f"--remote-debugging-port={args.port}",
            "--remote-debugging-address=127.0.0.1",
        ],
    )
    closed = asyncio.Event()
    context.on("close", lambda _: closed.set())

    try:
        await wait_until_ready(context, closed, args.port)

        stop = asyncio.Event()
        loop = asyncio.get_running_loop()
        for sig in (signal.SIGINT, signal.SIGTERM):
            with contextlib.suppress(NotImplementedError):
                loop.add_signal_handler(sig, stop.set)

        mode = "headless" if args.headless else "headed"
        print(f"CloakBrowser is ready ({mode}).", flush=True)
        print(f"Persistent profile: {profile}", flush=True)
        print(f"CDP endpoint: http://127.0.0.1:{args.port}", flush=True)

        stop_task = asyncio.create_task(stop.wait())
        disconnected_task = asyncio.create_task(closed.wait())
        try:
            await asyncio.wait(
                (stop_task, disconnected_task),
                return_when=asyncio.FIRST_COMPLETED,
            )
            if closed.is_set() and not stop.is_set():
                await raise_browser_exit(context)
        finally:
            stop_task.cancel()
            disconnected_task.cancel()
            await asyncio.gather(stop_task, disconnected_task, return_exceptions=True)
    finally:
        with contextlib.suppress(Exception):
            await context.close()


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
