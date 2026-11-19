"""Exercise the manual power saver with an isolated session and simulated devices."""
import copy
import os
from pathlib import Path
import runpy
import tempfile
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[1] / 'scripts/battery-eco'


class BatteryEcoTests(unittest.TestCase):
    def setUp(self):
        directory = self.enterContext(tempfile.TemporaryDirectory())
        self.enterContext(patch.dict(os.environ, XDG_RUNTIME_DIR=directory,
                                     HYPRLAND_INSTANCE_SIGNATURE='test-session'))
        self.api = runpy.run_path(str(SCRIPT))
        self.functions = self.api['enable'].__globals__
        self.profile = 'balanced'
        self.visuals = {name: True if isinstance(value, bool) else .85
                        for name, value in self.api['VISUALS'].items()}
        self.panel = {'value': 73, 'maximum': 100, 'keyboard': False}
        self.output = {
            'name': 'DP-8', 'description': 'Monitor', 'serial': 'test',
            'width': 1920, 'height': 1080, 'refreshRate': 119.996,
            'x': 1920, 'y': 0, 'scale': 1.0, 'transform': 0,
            'availableModes': ['1920x1080@120Hz', '1920x1080@60Hz',
                               '1920x1080@50Hz', '1280x720@48Hz'],
        }
        self.enterContext(patch.dict(
            self.functions,
            command=self.unexpected_command,
            read_profile=lambda: self.profile,
            set_profile=self.set_profile,
            read_visual=self.visuals.__getitem__,
            set_visual=self.visuals.__setitem__,
            brightness_devices=lambda: {'panel': self.panel.copy()},
            set_brightness=self.set_brightness,
            monitors=lambda: [copy.deepcopy(self.output)],
            set_monitor=self.set_monitor,
        ))

    def unexpected_command(self, *args):
        self.fail(f'Unexpected external command: {args}')

    def set_profile(self, value):
        self.profile = value

    def set_brightness(self, name, value):
        self.assertEqual(name, 'panel')
        self.panel['value'] = value

    def set_monitor(self, monitor, mode):
        self.assertEqual(monitor['name'], self.output['name'])
        self.output.update(width=mode['width'], height=mode['height'], refreshRate=mode['refresh'])

    def test_on_on_off_returns_to_the_first_snapshot(self):
        original = self.visuals.copy()
        self.api['enable']()
        self.assertEqual((self.profile, self.output['refreshRate'], self.panel['value']),
                         ('power-saver', 60, 25))
        self.assertEqual(self.visuals, self.api['VISUALS'])
        self.assertTrue(self.api['override_path']().is_file())
        self.api['enable']()
        self.api['disable']()
        self.assertEqual((self.profile, self.output['refreshRate'], self.panel['value']),
                         ('balanced', 119.996, 73))
        self.assertEqual(self.visuals, original)
        self.assertFalse(self.api['state_path']().exists())
        self.assertFalse(self.api['override_path']().exists())

    def test_mode_selection_keeps_resolution_and_existing_lower_rate(self):
        choose = self.api['economy_mode']
        self.assertEqual(choose(self.output | {'name': 'eDP-1'}), 50)
        self.assertEqual(choose(self.output | {'refreshRate': 50}), 50)
        self.assertIsNone(choose(self.output | {'availableModes': ['1280x720@48Hz']}))

    def test_manual_changes_survive_restore(self):
        self.api['enable']()
        self.output.update(x=8, refreshRate=50)
        self.panel['value'] = 57
        self.profile = 'performance'
        self.api['disable']()
        self.assertEqual((self.output['x'], self.output['refreshRate']), (8, 50))
        self.assertEqual((self.profile, self.panel['value']), ('performance', 57))

    def test_failure_after_external_write_restores_original_values(self):
        def fail_after_dimming(name, value):
            self.set_brightness(name, value)
            if value == 25:
                raise RuntimeError('failed readback')

        with patch.dict(self.functions, set_brightness=fail_after_dimming):
            with self.assertRaisesRegex(RuntimeError, 'failed readback'):
                self.api['enable']()
        self.assertEqual((self.profile, self.panel['value']), ('balanced', 73))
        self.assertFalse(self.api['state_path']().exists())

    def test_restore_retry_only_applies_unfinished_fields(self):
        def fail(_):
            raise RuntimeError('profile daemon unavailable')

        self.api['enable']()
        with patch.dict(self.functions, set_profile=fail):
            with self.assertRaisesRegex(RuntimeError, 'profile daemon unavailable'):
                self.api['disable']()
        self.assertEqual(self.api['load']()['phase'], 'restore-pending')
        self.assertEqual(self.panel['value'], 73)
        self.panel['value'] = 25  # A later manual edit matches the old economy value.
        self.api['disable']()
        self.assertEqual((self.profile, self.panel['value']), ('balanced', 25))
        self.assertFalse(self.api['state_path']().exists())

    def test_layout_choice_under_economy_becomes_restore_target(self):
        self.api['enable']()
        self.api['reconcile']({self.output['name']: {'width': 1920, 'height': 1080, 'refresh': 60}})
        self.api['disable']()
        self.assertEqual(self.output['refreshRate'], 60)

    def test_profile_change_requires_readback_and_no_interactive_auth(self):
        writes = []
        setter = self.api['set_profile']
        with patch.dict(self.functions, command=lambda *args: writes.append(args)):
            with self.assertRaises(RuntimeError):
                setter('power-saver')
        self.assertEqual(len(writes), 1)
        self.assertEqual(writes[0][0], 'busctl')
        self.assertIn('--allow-interactive-authorization=no', writes[0])


if __name__ == '__main__':
    unittest.main()
