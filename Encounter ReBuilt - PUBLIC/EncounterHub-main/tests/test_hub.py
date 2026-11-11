import hashlib
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
import hub
from app_main import command_action

class Commands(unittest.TestCase):
    def test_pause_never_resumes(self):
        self.assertEqual(command_action('Pause',{'Resume':1}),(None,'Paused',True))
    def test_trade_waits_for_pause(self):
        self.assertEqual(command_action('Trade Mode',{'Pause':1})[0],'Pause')
        self.assertIsNone(command_action('Trade Mode',{'Waiting for pause...':1})[0])
        self.assertEqual(command_action('Trade Mode',{'Resume':1,'Trade Mode':2})[0],'Trade Mode')
    def test_active_mode_is_idempotent(self):
        for command,caption in [('Trade Mode','Stop Trade Mode'),('Open Lockboxes','Stop Opening')]:
            self.assertTrue(command_action(command,{caption:1})[2])
            self.assertEqual(command_action('Pause',{caption:1})[0],caption)
    def test_resume_never_pauses(self):
        self.assertTrue(command_action('Resume',{'Pause':1})[2])
        self.assertEqual(command_action('Resume',{'Resume':1})[0],'Resume')

class Updates(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.root=Path(self.temp.name)
        self.addCleanup(self.temp.cleanup)
        self.old=b'VERSION="old"\n';self.new=b'VERSION="new"\n'
        (self.root/'app_main.py').write_bytes(self.old)
        self.manifest={'format':1,'version':'new','files':{'app_main.py':hashlib.sha256(self.new).hexdigest()}}
    def run_update(self,payload=None):
        calls=[]
        def remote(path,commit):
            calls.append((path,commit))
            return json.dumps(self.manifest).encode() if path=='update.json' else (self.new if payload is None else payload)
        with patch.object(hub,'api',return_value={'object':{'sha':'abc123'}}),patch.object(hub,'remote_file',side_effect=remote):
            result=hub.update(self.root)
        self.assertTrue(all(commit=='abc123' for _,commit in calls))
        return result
    def test_install_and_backup(self):
        self.run_update()
        self.assertEqual((self.root/'app_main.py').read_bytes(),self.new)
        self.assertEqual((self.root/'app_main.py.backup').read_bytes(),self.old)
        self.assertFalse((self.root/'app_main.py.download').exists())
    def test_bad_hash_preserves_install(self):
        with self.assertRaises(ValueError):self.run_update(b'tampered')
        self.assertEqual((self.root/'app_main.py').read_bytes(),self.old)
    def test_bad_syntax_preserves_install(self):
        payload=b'if !!!'
        self.manifest['files']['app_main.py']=hashlib.sha256(payload).hexdigest()
        with self.assertRaises(SyntaxError):self.run_update(payload)
        self.assertEqual((self.root/'app_main.py').read_bytes(),self.old)
    def test_manifest_cannot_overwrite_settings(self):
        self.manifest['files']['settings.json']='0'*64
        with self.assertRaises(ValueError):self.run_update()
    def test_no_download_if_current(self):
        (self.root/'app_main.py').write_bytes(self.new)
        self.assertIn('Already up to date',self.run_update())
    def test_offline_preserves_install(self):
        with patch.object(hub,'api',side_effect=OSError('offline')):
            with self.assertRaises(OSError):hub.update(self.root)
        self.assertEqual((self.root/'app_main.py').read_bytes(),self.old)

if __name__=='__main__':unittest.main()
