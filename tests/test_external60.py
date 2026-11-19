import os
from pathlib import Path
import runpy
import tempfile
import unittest
from unittest.mock import patch

BASE = Path(__file__).resolve().parents[1]
SOURCE = BASE/'scripts/toggle-main-monitor' if (BASE/'scripts/toggle-main-monitor').exists() else BASE/'outputs/toggle-main-monitor'


class External60Tests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        with patch.dict(os.environ, XDG_RUNTIME_DIR=self.temp.name, HYPRLAND_INSTANCE_SIGNATURE='test'):
            self.api = runpy.run_path(str(SOURCE))

    def feature(self, name):
        self.assertTrue(name in self.api, 'Missing external-only support: '+name)
        return self.api[name]

    def monitor(self):
        return {'name':'DP-8','width':1920,'height':1080,'refreshRate':120,
                'availableModes':['1920x1080@120.00Hz','1920x1080@59.94Hz','1920x1080@60.00Hz']}

    def test_prefers_exact_supported_60_hz(self):
        self.assertEqual(self.feature('external_60_mode')(self.monitor()), '1920x1080@60.00')

    def test_missing_60_hz_refuses_transition(self):
        m=self.monitor();m['availableModes']=['1920x1080@120.00Hz']
        with self.assertRaises(RuntimeError):self.feature('external_60_mode')(m)

    def test_external_mode_preserves_base_snapshot(self):
        external=self.monitor();internal={'name':'eDP-2'}
        original={'external':'DP-6','internal':'eDP-1','monitors':{
            'DP-6':{'mode':'1920x1080@120','position':'1920x0','scale':1,'transform':0},
            'eDP-1':{'mode':'1920x1080@48.069','position':'0x0','scale':1,'transform':0}}}
        state=self.feature('build_state')('external',original,external,internal)
        self.assertTrue(state['external_only'])
        self.assertFalse(state['laptop_only'])
        self.assertEqual(state['external'],'DP-8')
        self.assertEqual(state['monitors']['DP-8']['mode'],'1920x1080@60.00')
        self.assertEqual(state['monitors']['DP-8']['position'],'0x0')
        self.assertEqual(original['monitors']['DP-6']['mode'],'1920x1080@120')

    def test_special_workspaces_without_numeric_ids_do_not_break_switch(self):
        external = self.monitor() | {'x': 1920, 'y': 0, 'scale': 1, 'activeWorkspace': {'name': '2'}}
        internal = {'name': 'eDP-1', 'x': 0, 'y': 0, 'scale': 1, 'width': 1920, 'height': 1080,
                    'refreshRate': 60, 'activeWorkspace': {'name': '9'}}
        numbered = {'name': '9', 'type': 'normal', 'id': 9, 'monitor': 'eDP-1'}
        special = {'name': 'special:music', 'type': 'special', 'monitor': 'DP-8'}
        preview = {
            ('monitors', 'all'): [external, internal], ('monitors',): [external],
            ('workspaces',): [numbered, special], ('activeworkspace',): {'name': '2'},
        }
        evaluate = []
        with patch.dict(self.api['capture'].__globals__, query=lambda *args: preview[args],
                        command=lambda *args: '', evaluate=evaluate.append, runtime_visuals=lambda: {},
                        focus_workspace=lambda name: None):
            snapshot = self.api['capture'](external, internal)
            self.assertEqual([w['name'] for w in snapshot['workspaces']], ['9'])
            self.assertEqual(self.api['apply']('external', snapshot, 120), 'external')
        self.assertTrue(any('workspace=9' in call and 'DP-8' in call for call in evaluate))
        self.assertFalse(any('special:music' in call for call in evaluate))


if __name__=='__main__':unittest.main()
