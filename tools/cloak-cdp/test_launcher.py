from __future__ import annotations

import shutil
import stat
import tempfile
import unittest
from pathlib import Path

from launcher import (
    FINGERPRINT_FILENAME,
    PROFILE_DIRNAME,
    resolve_profile_fingerprint,
)


class ProfileFingerprintTests(unittest.TestCase):
    def test_new_profile_generates_and_reuses_seed(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_dir:
            state_dir = Path(temporary_dir) / "cloak-cdp"
            profile = state_dir / PROFILE_DIRNAME

            first = resolve_profile_fingerprint(state_dir, None)
            (profile / "Cookies").touch()
            second = resolve_profile_fingerprint(state_dir, None)

            self.assertGreaterEqual(first, 10000)
            self.assertLessEqual(first, 99999)
            self.assertEqual(second, first)
            self.assertEqual(
                (state_dir / FINGERPRINT_FILENAME).read_text(encoding="utf-8"),
                f"{first}\n",
            )
            self.assertEqual(
                stat.S_IMODE((state_dir / FINGERPRINT_FILENAME).stat().st_mode),
                0o600,
            )
            self.assertEqual(stat.S_IMODE(state_dir.stat().st_mode), 0o700)
            self.assertEqual(stat.S_IMODE(profile.stat().st_mode), 0o700)

    def test_recorded_seed_cannot_be_changed(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_dir:
            state_dir = Path(temporary_dir) / "cloak-cdp"
            resolve_profile_fingerprint(state_dir, 12345)

            with self.assertRaisesRegex(RuntimeError, "refusing requested fingerprint"):
                resolve_profile_fingerprint(state_dir, 54321)

    def test_existing_profile_requires_its_known_seed(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_dir:
            state_dir = Path(temporary_dir) / "cloak-cdp"
            profile = state_dir / PROFILE_DIRNAME
            profile.mkdir(parents=True)
            (profile / "Cookies").touch()

            with self.assertRaisesRegex(RuntimeError, "has no .* record"):
                resolve_profile_fingerprint(state_dir, None)

    def test_existing_profile_can_record_its_known_seed_once(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_dir:
            state_dir = Path(temporary_dir) / "cloak-cdp"
            profile = state_dir / PROFILE_DIRNAME
            profile.mkdir(parents=True)
            (profile / "Cookies").touch()

            seed = resolve_profile_fingerprint(state_dir, 24680)

            self.assertEqual(seed, 24680)
            self.assertEqual(resolve_profile_fingerprint(state_dir, None), seed)

    def test_seed_does_not_authorize_replacing_a_missing_profile(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_dir:
            state_dir = Path(temporary_dir) / "cloak-cdp"
            resolve_profile_fingerprint(state_dir, 13579)
            shutil.rmtree(state_dir / PROFILE_DIRNAME)

            with self.assertRaisesRegex(RuntimeError, "profile .* is missing"):
                resolve_profile_fingerprint(state_dir, None)


if __name__ == "__main__":
    unittest.main()
