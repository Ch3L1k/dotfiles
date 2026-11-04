import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

ROOT=Path(__file__).resolve().parents[1]
class Installer(unittest.TestCase):
 def invoke(self,home,*args):
  return subprocess.run([sys.executable,str(ROOT/'install.py'),'--home',str(home),*args],capture_output=True,text=True,timeout=10)
 def test_preview_does_not_write(self):
  with tempfile.TemporaryDirectory() as d:
   h=Path(d);r=self.invoke(h,'--component','fastfetch')
   self.assertEqual(r.returncode,0,r.stderr);self.assertEqual(list(h.iterdir()),[])
 def test_apply_backups_and_template_rendering(self):
  with tempfile.TemporaryDirectory() as d:
   h=Path(d);p=h/'.config/fastfetch/config.jsonc';p.parent.mkdir(parents=True);p.write_text('old file')
   r=self.invoke(h,'--apply','--component','fastfetch')
   self.assertEqual(r.returncode,0,r.stderr)
   backups=list((h/'.local/state/dotfiles-backups').glob('*/.config/fastfetch/config.jsonc'))
   self.assertEqual(len(backups),1);self.assertEqual(backups[0].read_text(),'old file')
   self.assertNotIn('@HOME@',p.read_text());self.assertIn(str(h),p.read_text())
   self.assertFalse((h/'.config/autostart').exists())
 def test_reject_parent_symlink(self):
  with tempfile.TemporaryDirectory() as d, tempfile.TemporaryDirectory() as outside:
   h=Path(d);(h/'.config').symlink_to(outside,target_is_directory=True)
   r=self.invoke(h,'--apply','--component','fastfetch')
   self.assertNotEqual(r.returncode,0);self.assertEqual(list(Path(outside).iterdir()),[])
 def test_unknown_component_does_not_write(self):
  with tempfile.TemporaryDirectory() as d:
   h=Path(d);r=self.invoke(h,'--apply','--component','unknown')
   self.assertNotEqual(r.returncode,0);self.assertEqual(list(h.iterdir()),[])
if __name__=='__main__':unittest.main()
