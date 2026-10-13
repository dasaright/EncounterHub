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


class Bundles(unittest.TestCase):
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.root=Path(self.temp.name);self.addCleanup(self.temp.cleanup)
        self.payloads={'app_main.py':b'VERSION="new"\n','hub.py':b'HUB_BUNDLE_SUPPORT=True\n','Launch Hub.vbs':b'Option Explicit\n','Launch Hub.cmd':b'@echo off\n','update.json':b'{}'}
        self.manifest={'format':1,'version':'new','files':{n:hashlib.sha256(b).hexdigest() for n,b in self.payloads.items()}}
        (self.root/'settings.json').write_text('KEEP')
    def invoke(self):
        import app_main
        def remote(name,commit):
            self.assertEqual(commit,'pinned')
            from urllib.parse import unquote
            return json.dumps(self.manifest).encode() if name in ('bundle.json','desktop-bundle.json') else self.payloads[unquote(name)]
        with patch.object(hub,'api',return_value={'object':{'sha':'pinned'}}),patch.object(hub,'remote_file',side_effect=remote):
            return app_main.update_bundle(self.root)
    def test_full_install_preserves_settings(self):
        self.invoke()
        for name,data in self.payloads.items():self.assertEqual((self.root/name).read_bytes(),data)
        self.assertEqual((self.root/'settings.json').read_text(),'KEEP')
    def test_validate_all_before_install(self):
        self.payloads['hub.py']=b'tampered'
        with self.assertRaises(ValueError):self.invoke()
        self.assertFalse((self.root/'app_main.py').exists())
    def test_unknown_file_rejected(self):
        self.manifest['files']['settings.json']='0'*64
        with self.assertRaises(ValueError):self.invoke()
        self.assertEqual((self.root/'settings.json').read_text(),'KEEP')
    def test_install_failure_rolls_back(self):
        (self.root/'app_main.py').write_bytes(b'OLD')
        import app_main
        real_replace=app_main.os.replace
        def replace(src,dst):
            if Path(dst).name=='hub.py':raise OSError('simulated install failure')
            return real_replace(src,dst)
        with patch.object(app_main.os,'replace',side_effect=replace):
            with self.assertRaises(OSError):self.invoke()
        self.assertEqual((self.root/'app_main.py').read_bytes(),b'OLD')

@unittest.skipUnless(sys.platform=='win32','Windows kernel integration test')
class Ownership(unittest.TestCase):
    def test_private_job_kills_descendants_and_keeps_unrelated_process(self):
        import subprocess
        import time
        from app_main import JobProcess
        unrelated=subprocess.Popen([sys.executable,'-c','import time; time.sleep(60)'])
        owned=None
        try:
            owned=JobProcess(Path(sys.executable),['-c','import subprocess,sys,time; subprocess.Popen([sys.executable,"-c","import time; time.sleep(60)"]);time.sleep(60)'])
            deadline=time.monotonic()+10
            while len(owned.members())<2 and time.monotonic()<deadline:time.sleep(.1)
            self.assertGreaterEqual(len(owned.members()),2)
            self.assertNotIn(unrelated.pid,owned.members())
            from app_main import advance_stop
            owned.terminate()
            session={'process':owned,'stop_phase':'bot','stopping':True}
            deadline=time.monotonic()+10
            while owned.poll() is None and time.monotonic()<deadline:time.sleep(.1)
            self.assertIsNotNone(owned.poll())
            advance_stop(session)
            deadline=time.monotonic()+10
            while owned.members() and time.monotonic()<deadline:time.sleep(.1)
            self.assertEqual(owned.members(),[])
            self.assertIsNone(unrelated.poll())
        finally:
            if owned:owned.close()
            unrelated.terminate();unrelated.wait(timeout=10)


class StopAndMonitoring(unittest.TestCase):
    def test_clients_wait_until_bot_exit(self):
        from app_main import advance_stop
        from unittest.mock import Mock
        process=Mock();process.poll.return_value=None
        session={'process':process,'stop_phase':'bot','stopping':True,'pending':'Pause'}
        self.assertFalse(advance_stop(session)[1]);process.shutdown.assert_not_called()
        process.poll.return_value=0;process.members.return_value=[234]
        self.assertFalse(advance_stop(session)[1]);process.shutdown.assert_called_once()
        process.members.return_value=[]
        self.assertTrue(advance_stop(session)[1]);process.shutdown.assert_called_once()
        self.assertFalse(session['stopping']);self.assertIsNone(session['pending'])
    def test_unselected_jobs_are_not_touched(self):
        from app_main import advance_stop
        from unittest.mock import Mock
        selected=Mock();unrelated=Mock();selected.poll.return_value=0;selected.members.return_value=[]
        advance_stop({'process':selected,'stop_phase':'bot','stopping':True})
        selected.shutdown.assert_called_once();unrelated.shutdown.assert_not_called()
    def test_idle_running_monitor_does_not_read_bot_windows(self):
        from app_main import Hub
        from unittest.mock import Mock
        h=Hub.__new__(Hub);h.native=Mock();h.report=Mock();h.sync_storage=Mock()
        process=Mock();process.poll.return_value=None
        session={'process':process,'stopping':False,'next_games':float('inf'),'phase':'done','pending':None}
        h.step('character',session)
        h.native.window.assert_not_called();h.native.children.assert_not_called();h.native.text.assert_not_called()
    def test_worker_reports_without_touching_tk(self):
        from app_main import Hub
        import queue
        h=Hub.__new__(Hub);h.monitor_events=queue.Queue()
        h.report('character','status','running')
        self.assertEqual(h.monitor_events.get_nowait(),('character','status','running'))



class CheckboxSync(unittest.TestCase):
    def setup_hub(self):
        from app_main import Hub
        from unittest.mock import Mock
        h=Hub.__new__(Hub);h.native=Mock();h.report=Mock();h.sync_storage=Mock();h.native.u.IsWindowEnabled.return_value=True
        session={'next_options':0,'options':{'render':10},'option_requests':{},'option_sent':set()}
        return h,session
    def test_external_change_is_reflected_without_click(self):
        h,s=self.setup_hub();h.native.checked.return_value=True
        h.sync_options('char',s)
        h.report.assert_any_call('char','render','1');h.native.click.assert_not_called()
    def test_desired_state_clicks_once_and_waits_for_confirmation(self):
        import time
        h,s=self.setup_hub();h.native.checked.return_value=False
        s['option_requests']['render']=(True,time.monotonic()+10)
        h.sync_options('char',s);s['next_options']=0;h.sync_options('char',s)
        h.native.click.assert_called_once_with(10)
        h.native.checked.return_value=True;s['next_options']=0;h.sync_options('char',s)
        self.assertNotIn('render',s['option_requests'])
        h.report.assert_any_call('char','_render_enabled',True)
    def test_matching_state_is_not_toggled_off(self):
        import time
        h,s=self.setup_hub();h.native.checked.return_value=True
        s['option_requests']['render']=(True,time.monotonic()+10)
        h.sync_options('char',s);h.native.click.assert_not_called()

@unittest.skipUnless(sys.platform=='win32','Windows Tk row control test')
class RowControls(unittest.TestCase):
    def test_columns_and_row_buttons_do_not_change_selection(self):
        import os
        import tkinter as tk
        from app_main import Hub
        from unittest.mock import Mock
        with tempfile.TemporaryDirectory() as directory:
            folder=Path(directory);(folder/'Config').mkdir()
            (folder/'Config'/'characters.ini').write_text('[Character One]\n')
            exe=folder/'Encounter_ReBuilt.exe';exe.touch()
            settings=folder/'EncounterHub';settings.mkdir();(settings/'settings.json').write_text(json.dumps({'bot_path':str(exe),'selected':[]}))
            root=tk.Tk()
            with patch.dict(os.environ,{'LOCALAPPDATA':directory}):
                h=Hub(root,'test')
            try:
                root.update()
                self.assertEqual(tuple(h.tree['displaycolumns']),('check','character','status','command','render','ontop','pause','resume','stop','launch'))
                h.command=Mock();h.launch=Mock();h.stop=Mock()
                h.row_widgets['Character One']['widgets']['pause'].invoke()
                h.command.assert_called_once_with('Pause',['Character One'])
                h.row_widgets['Character One']['widgets']['launch'].invoke()
                h.launch.assert_called_once_with(['Character One'])
                h.row_widgets['Character One']['widgets']['stop'].invoke()
                h.stop.assert_called_once_with(['Character One'])
                self.assertEqual(h.checked,set())
            finally:
                h.monitor_stop.set();h.monitor_worker.join(timeout=5);root.destroy()

if __name__=='__main__':unittest.main()
