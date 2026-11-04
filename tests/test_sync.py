# Copyright (c) 2026 Ch3L1k. SPDX-License-Identifier: MIT
import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest

spec = importlib.util.spec_from_file_location("dotfiles_sync", Path(__file__).resolve().parents[1] / "sync.py")
sync = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sync)


class SyncTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.repo, self.home = self.root / "repo", self.root / "home"
        self.repo.mkdir()
        self.source = self.home / ".config/hypr/config/misc.lua"
        self.source.parent.mkdir(parents=True)
        self.target = self.repo / "config/hypr/config/misc.lua"
        self.target.parent.mkdir(parents=True)
        self.source.write_text("return true\n")
        self.target.write_bytes(self.source.read_bytes())
        for args in (("init", "-b", "main"), ("config", "user.name", "Test"),
                     ("config", "user.email", "test@example.invalid"), ("add", "."),
                     ("commit", "-m", "Initial")):
            sync.git(self.repo, *args)

    def test_unchanged_run_creates_no_commit(self):
        before = sync.git(self.repo, "rev-parse", "HEAD")
        self.assertEqual(sync.sync(self.repo, self.home, apply=True)["state"], "unchanged")
        self.assertEqual(sync.git(self.repo, "rev-parse", "HEAD"), before)

    def test_changed_config_is_committed_but_untracked_files_are_not(self):
        self.source.write_text("focus_on_activate = true\n")
        (self.repo / "private-notes.txt").write_text("not part of the snapshot")
        self.assertEqual(sync.sync(self.repo, self.home, apply=True)["state"], "updated")
        self.assertEqual(self.target.read_bytes(), self.source.read_bytes())
        self.assertNotIn("private-notes.txt", sync.git(self.repo, "ls-files"))
        self.assertEqual(sync.sync(self.repo, self.home, apply=True)["state"], "unchanged")

    def test_manual_checkout_edit_is_preserved(self):
        self.target.write_text("manual change\n")
        self.source.write_text("different live setting\n")
        with self.assertRaisesRegex(ValueError, "manual changes"):
            sync.sync(self.repo, self.home, apply=True)
        self.assertEqual(self.target.read_text(), "manual change\n")

    def test_credential_guard_stops_before_any_write(self):
        before = self.target.read_bytes()
        self.source.write_text("token = 'ghp_" + "A" * 40 + "'\n")
        with self.assertRaisesRegex(ValueError, "Potential credential"):
            sync.sync(self.repo, self.home, apply=True)
        self.assertEqual(self.target.read_bytes(), before)
        self.assertFalse(sync.git(self.repo, "status", "--porcelain"))


if __name__ == "__main__":
    unittest.main()
