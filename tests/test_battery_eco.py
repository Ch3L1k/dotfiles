import runpy
import tempfile
import unittest
from unittest.mock import patch
from pathlib import Path

BASE = Path(__file__).resolve().parents[1]
SOURCE = BASE / 'scripts/battery-eco' if (BASE / 'scripts/battery-eco').exists() else BASE / 'outputs/battery-eco'


class BatteryEcoTests(unittest.TestCase):
    def setUp(self):
        self.api = runpy.run_path(str(SOURCE)) if SOURCE.exists() else {}

    def feature(self, name):
        self.assertTrue(name in self.api, 'Battery economy feature is not implemented: ' + name)
        return self.api[name]

    def fixture(self, directory):
        root = Path(directory) / 'sys'
        files = {
            'devices/system/cpu/intel_pstate/no_turbo': '0',
            'devices/system/cpu/cpufreq/policy0/scaling_min_freq': '800000',
            'devices/system/cpu/cpufreq/policy0/scaling_max_freq': '4300000',
            'devices/system/cpu/cpufreq/policy1/scaling_min_freq': '2200000',
            'devices/system/cpu/cpufreq/policy1/scaling_max_freq': '3000000',
            'class/leds/dell::kbd_backlight/brightness': '2',
        }
        for name, value in files.items():
            p = root / name
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(value)
        return root, files

    def test_roundtrip_restores_cpu_limits_and_keyboard(self):
        # Catches dropped snapshots or restoring defaults instead of actual values.
        enable, disable = self.feature('cpu_enable'), self.feature('cpu_restore')
        with tempfile.TemporaryDirectory() as directory:
            root, original = self.fixture(directory)
            saved = Path(directory) / 'state.json'
            enable(root, saved)
            self.assertEqual((root / 'devices/system/cpu/intel_pstate/no_turbo').read_text(), '1')
            self.assertEqual((root / 'devices/system/cpu/cpufreq/policy1/scaling_min_freq').read_text(), '1800000')
            self.assertEqual((root / 'class/leds/dell::kbd_backlight/brightness').read_text(), '0')
            disable(root, saved)
            for name, value in original.items():
                self.assertEqual((root / name).read_text(), value)
            self.assertFalse(saved.exists())

    def test_second_enable_preserves_original_snapshot(self):
        # Catches an on/on/off cycle restoring the economy limit as the original.
        enable, disable = self.feature('cpu_enable'), self.feature('cpu_restore')
        with tempfile.TemporaryDirectory() as directory:
            root, _ = self.fixture(directory)
            saved = Path(directory) / 'state.json'
            enable(root, saved)
            snapshot = saved.read_bytes()
            enable(root, saved)
            self.assertEqual(saved.read_bytes(), snapshot)
            disable(root, saved)
            self.assertEqual((root / 'devices/system/cpu/cpufreq/policy0/scaling_max_freq').read_text(), '4300000')

    def test_existing_lower_limit_is_not_increased(self):
        enable = self.feature('cpu_enable')
        with tempfile.TemporaryDirectory() as directory:
            root, _ = self.fixture(directory)
            p = root / 'devices/system/cpu/cpufreq/policy0/scaling_max_freq'
            p.write_text('1200000')
            enable(root, Path(directory) / 'state.json')
            self.assertEqual(p.read_text(), '1200000')

    def test_modes_preserve_resolution_and_avoid_unsupported_rates(self):
        choose = self.feature('economy_mode')
        m = {'name':'eDP-1', 'width':1920, 'height':1080, 'refreshRate':60.128,
             'availableModes':['1920x1080@60.13Hz','1920x1080@48.07Hz','1280x720@60Hz']}
        self.assertEqual(choose(m), '1920x1080@48.07')
        m['name'] = 'DP-8'
        self.assertEqual(choose(m), '1920x1080@60.13')
        m['availableModes'] = ['1920x1080@120Hz']
        self.assertIsNone(choose(m))

    def test_driver_success_without_changed_gpu_limit_does_not_claim_applied(self):
        # Catches trusting nvidia-smi's exit status when firmware ignores its request.
        apply = self.feature('gpu_set_limit')
        xml = '<nvidia_smi_log><gpu><uuid>GPU-test</uuid><requested_power_limit>80 W</requested_power_limit><current_power_limit>40 W</current_power_limit><min_power_limit>1 W</min_power_limit></gpu></nvidia_smi_log>'
        def external(*args):
            return xml if '-x' in args else 'Power limit set successfully'
        with tempfile.TemporaryDirectory() as directory:
            state = Path(directory) / 'gpu.json'
            with patch.dict(apply.__globals__, command=external):
                self.assertFalse(apply(state))
            self.assertFalse(state.exists(), 'Unchanged hardware must not retain an applied-limit snapshot')

    def test_failed_hardware_restore_still_restores_desktop(self):
        # Catches coupling UI restoration to sudo/hardware success.
        disable = self.feature('disable')
        profile = ['power-saver']
        def external(*args):
            if args == ('powerprofilesctl', 'get'):
                return profile[0]
            if args[:2] == ('powerprofilesctl', 'set'):
                profile[0] = args[2]
                return ''
            raise AssertionError(args)
        def unavailable(_):
            raise RuntimeError('sudo failed')
        with tempfile.TemporaryDirectory() as directory:
            state = Path(directory) / 'desktop.json'
            state.write_text('{"brightness":{},"monitors":[],"signature":"old-session","profile":"balanced","options":{},"active":true}')
            with patch.dict(disable.__globals__, command=external, privileged=unavailable):
                with self.assertRaises(RuntimeError):
                    disable(state)
            self.assertEqual(profile[0], 'balanced')
            self.assertTrue(state.exists(), 'Keep original snapshot when hardware still needs recovery')

    def test_partial_hardware_start_is_rolled_back(self):
        # Catches hardware changing CPU and then failing before returning to the UI helper.
        enable = self.feature('enable')
        hardware = {'limited': False}
        snapshot = {'brightness':{}, 'monitors':[], 'signature':'old-session',
                    'profile':'power-saver', 'options':{}, 'active':False}
        def external(*args):
            if args == ('powerprofilesctl', 'get'):
                return 'power-saver'
            raise AssertionError(args)
        def hardware_boundary(action):
            hardware['limited'] = action == 'on'
            if action == 'on':
                raise RuntimeError('GPU query failed after CPU changes')
        with tempfile.TemporaryDirectory() as directory:
            state = Path(directory) / 'desktop.json'
            with patch.dict(enable.__globals__, command=external, privileged=hardware_boundary,
                            desktop_snapshot=lambda: dict(snapshot)):
                with self.assertRaises(RuntimeError):
                    enable(state)
            self.assertFalse(hardware['limited'])
            self.assertFalse(state.exists())


if __name__ == '__main__':
    unittest.main()
