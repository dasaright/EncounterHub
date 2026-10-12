import json
import os
from pathlib import Path
import tempfile
import threading
import time
import unittest
from unittest.mock import patch,Mock
import sys
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
import supervisor

class FakeOwnedProcess:
    def __init__(self,exe,args=()):self.pid=1234;self.alive=True;self.clients=True
    def poll(self):return None if self.alive else 0
    def members(self):return ([1234] if self.alive else [])+([2345] if self.clients else [])
    def games(self):return [2345] if self.clients else []
    def terminate(self):self.alive=False
    def shutdown(self):self.alive=False;self.clients=False
    def close(self):self.shutdown()

class Reconnection(unittest.TestCase):
    def test_new_gui_reconnects_without_stopping_owned_processes(self):
        with tempfile.TemporaryDirectory() as directory,patch('app_main.JobProcess',FakeOwnedProcess):
            endpoint=Path(directory)/'endpoint.json'
            thread=threading.Thread(target=supervisor.serve,args=(endpoint,),daemon=True);thread.start()
            deadline=time.monotonic()+5
            while not endpoint.exists() and time.monotonic()<deadline:time.sleep(.02)
            client=supervisor.Broker(json.loads(endpoint.read_text()))
            record=client.call('launch',exe=sys.executable,character='Char')
            identifier=record['identifier'];self.assertEqual(client.call('games',identifier=identifier),[2345])
            del client
            replacement=supervisor.Broker(json.loads(endpoint.read_text()))
            snapshot=replacement.call('snapshot');self.assertTrue(snapshot[0]['active']);self.assertEqual(snapshot[0]['character'],'Char')
            self.assertIsNone(replacement.call('poll',identifier=identifier))
            replacement.call('stopbot',identifier=identifier)
            self.assertEqual(replacement.call('poll',identifier=identifier),0)
            self.assertEqual(replacement.call('games',identifier=identifier),[2345])
            replacement.call('shutdown',identifier=identifier);self.assertEqual(replacement.call('members',identifier=identifier),[])
            replacement.call('exit');thread.join(timeout=5);self.assertFalse(thread.is_alive())
    def test_wrong_token_cannot_control_jobs(self):
        with tempfile.TemporaryDirectory() as directory,patch('app_main.JobProcess',FakeOwnedProcess):
            endpoint=Path(directory)/'endpoint.json'
            thread=threading.Thread(target=supervisor.serve,args=(endpoint,),daemon=True);thread.start()
            deadline=time.monotonic()+5
            while not endpoint.exists() and time.monotonic()<deadline:time.sleep(.02)
            details=json.loads(endpoint.read_text());wrong=supervisor.Broker({**details,'token':'wrong'})
            with self.assertRaises(OSError):wrong.call('launch',exe=sys.executable,character='Char')
            client=supervisor.Broker(details);self.assertEqual(client.call('snapshot'),[]);client.call('exit');thread.join(timeout=5)

try:
    import PySide6
    QT_AVAILABLE=True
except ImportError:QT_AVAILABLE=False

@unittest.skipUnless(QT_AVAILABLE,'Qt dependency required')
class QtDesktop(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        os.environ.setdefault('QT_QPA_PLATFORM','offscreen')
        from PySide6.QtWidgets import QApplication
        cls.app=QApplication.instance() or QApplication([])
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory();self.addCleanup(self.temp.cleanup)
        folder=Path(self.temp.name);(folder/'Config').mkdir();(folder/'Config'/'characters.ini').write_text('[Character One]\n')
        exe=folder/'Encounter_ReBuilt.exe';exe.touch();settings=folder/'EncounterHub';settings.mkdir();(settings/'settings.json').write_text(json.dumps({'bot_path':str(exe),'selected':[]}))
        from qt_app import Desktop
        with patch.dict(os.environ,{'LOCALAPPDATA':str(folder)}):self.window=Desktop('test',start_supervisor=False)
        self.window.show();self.app.processEvents()
        self.addCleanup(self.cleanup)
    def cleanup(self):
        self.window.monitor_stop.set();self.window.monitor_worker.join(timeout=5);self.window.restarting=True;self.window.close();self.app.processEvents()
    def test_native_columns_and_action_buttons(self):
        from qt_app import COLUMNS
        self.assertEqual(self.window.table.columnCount(),10)
        self.assertEqual(COLUMNS,('check','character','status','command','render','ontop','pause','resume','stop','launch'))
        self.window.command=Mock();self.window.launch=Mock();self.window.stop=Mock()
        self.window.row_widgets['Character One']['pause'].click();self.window.command.assert_called_once_with('Pause',['Character One'])
        self.window.row_widgets['Character One']['launch'].click();self.window.launch.assert_called_once_with(['Character One'])
        self.assertEqual(self.window.checked,set())
    def test_columns_resize_without_overlay_misalignment(self):
        w=self.window;before=w.table.columnWidth(1)
        w.resize(1700,640);self.app.processEvents()
        self.assertGreater(w.table.columnWidth(1),before)
        for key in ('pause','resume','stop','launch'):
            widget=w.row_widgets['Character One'][key]
            self.assertGreaterEqual(widget.width(),58)
        w.resize(900,460);self.app.processEvents()
        self.assertGreaterEqual(w.table.horizontalScrollBar().maximum(),0)
    def test_update_buttons_position_and_no_silent_install(self):
        self.assertLess(self.window.check_button.pos().y(),self.window.update_button.pos().y())
        self.assertFalse(self.window.update_button.isEnabled())
        self.assertFalse(self.window.busy_update)
    def test_restart_does_not_send_shutdown(self):
        w=self.window;w.broker=Mock();w.monitor_stop.set();w.monitor_worker.join(timeout=5)
        with patch('qt_app.subprocess.Popen') as spawn:w.restart()
        spawn.assert_called_once();w.broker.call.assert_not_called();self.assertTrue(w.restarting)

if __name__=='__main__':unittest.main()

@unittest.skipUnless(sys.platform=='win32','Windows supervisor integration')
class RealSupervisor(unittest.TestCase):
    def test_client_exit_reconnect_and_selective_shutdown(self):
        import subprocess
        with tempfile.TemporaryDirectory() as directory:
            endpoint=Path(directory)/'endpoint.json'
            repo=Path(__file__).resolve().parents[1]
            keeper=subprocess.Popen([sys.executable,'-c','from pathlib import Path;from supervisor import serve;serve(Path('+repr(str(endpoint))+'))'],cwd=repo,creationflags=subprocess.CREATE_NO_WINDOW)
            unrelated=subprocess.Popen([sys.executable,'-c','import time;time.sleep(60)'],creationflags=subprocess.CREATE_NO_WINDOW)
            broker=None
            try:
                deadline=time.monotonic()+10
                while not endpoint.exists() and time.monotonic()<deadline:time.sleep(.05)
                details=json.loads(endpoint.read_text());broker=supervisor.Broker(details)
                # The first GUI-like client launches bots and then completely exits.
                program='import json,sys;from supervisor import Broker; b=Broker('+repr(details)+'); print(json.dumps(b.call("launch",exe=sys.executable,character="Live Bot",arguments=["-c","import subprocess,sys,time;subprocess.Popen([sys.executable,\\\"-c\\\",\\\"import time;time.sleep(60)\\\"]);time.sleep(60)"])))'
                first=subprocess.run([sys.executable,'-c',program],cwd=repo,capture_output=True,text=True,timeout=10)
                self.assertEqual(first.returncode,0,first.stderr)
                record=json.loads(first.stdout);identifier=record['identifier']
                deadline=time.monotonic()+10
                while len(broker.call('members',identifier=identifier))<2 and time.monotonic()<deadline:time.sleep(.05)
                replacement=supervisor.Broker(json.loads(endpoint.read_text()))
                self.assertIsNone(replacement.call('poll',identifier=identifier))
                self.assertTrue(replacement.call('snapshot')[0]['active'])
                replacement.call('stopbot',identifier=identifier)
                deadline=time.monotonic()+10
                while replacement.call('poll',identifier=identifier) is None and time.monotonic()<deadline:time.sleep(.05)
                self.assertIsNotNone(replacement.call('poll',identifier=identifier))
                replacement.call('shutdown',identifier=identifier)
                deadline=time.monotonic()+10
                while replacement.call('members',identifier=identifier) and time.monotonic()<deadline:time.sleep(.05)
                self.assertEqual(replacement.call('members',identifier=identifier),[])
                self.assertIsNone(unrelated.poll())
                replacement.call('exit');keeper.wait(timeout=10)
            finally:
                if broker and keeper.poll() is None:
                    try:
                        for record in broker.call('snapshot'):broker.call('shutdown',identifier=record['identifier'])
                        broker.call('exit')
                    except OSError:pass
                if keeper.poll() is None:keeper.terminate()
                keeper.wait(timeout=10);unrelated.terminate();unrelated.wait(timeout=10)
