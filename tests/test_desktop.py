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
    def test_icon_has_full_size_artwork_and_updates_external_icon(self):
        import base64
        from qt_app import app_icon,write_app_icon,APP_ICON_DATA
        icon=app_icon()
        self.assertEqual(icon.pixmap(256,256).width(),256)
        self.assertFalse(self.window.windowIcon().isNull())
        self.assertFalse(self.window.brand_icon.pixmap().isNull())
        root=Path(self.temp.name)
        (root/'taco.ico').write_bytes(b'old icon')
        target=write_app_icon(root)
        self.assertEqual(target.read_bytes(),base64.b64decode(APP_ICON_DATA))
        self.assertEqual(target.read_bytes(),(Path(__file__).resolve().parents[1]/'assets/taco-dagger.ico').read_bytes())

    def test_desktop_exposes_pie_sync_hook(self):
        import app_main as engine
        self.assertIs(self.window.sync_pie.__func__,engine.Hub.sync_pie)

    def test_native_columns_and_action_buttons(self):
        from qt_app import COLUMNS
        self.assertEqual(self.window.table.columnCount(),19)
        self.assertEqual(self.window.table.horizontalHeaderItem(17).text(),'Total Pie')
        self.assertEqual(self.window.table.horizontalHeaderItem(18).text(),'Pie/hr')
        self.assertEqual(COLUMNS,('check','account','character','farm','status','command','render','ontop','pause','resume','trade','stop','launch','buycons','automatic','manual','storage','total_pie','pie_hr'))
        self.assertEqual(self.window.row_widgets['Character One']['farm'].currentText(),'Ministerial')
        self.assertEqual(self.window.tree.set('Character One','character'),'Character One')
        self.window.command=Mock();self.window.launch=Mock();self.window.stop=Mock()
        self.window.row_widgets['Character One']['pause'].click();self.window.command.assert_called_once_with('Pause',['Character One'])
        self.window.command.reset_mock();self.window.row_widgets['Character One']['trade'].click()
        self.window.command.assert_called_once_with('Trade Mode',['Character One'])
        self.window.row_widgets['Character One']['launch'].click();self.window.launch.assert_called_once_with(['Character One'])
        self.assertFalse(self.window.row_widgets['Character One']['buycons'].isEnabled())
        self.assertEqual(self.window.row_widgets['Character One']['automatic'].currentText(),'Full Conset')
        self.assertEqual(self.window.row_widgets['Character One']['manual'].currentText(),'Full Conset')
        self.assertEqual(self.window.checked,set())
    def test_columns_resize_without_overlay_misalignment(self):
        w=self.window;before=w.table.columnWidth(1)
        w.resize(1700,640);self.app.processEvents();self.app.processEvents()
        w.resize(1700,640);self.app.processEvents();w.fit_columns();self.app.processEvents()
        for key in ('pause','resume','trade','stop','launch','buycons'):
            widget=w.row_widgets['Character One'][key]
            self.assertGreaterEqual(widget.width(),58)
        w.resize(900,460);self.app.processEvents()
        self.assertGreaterEqual(w.table.horizontalScrollBar().maximum(),0)
    def test_manual_widths_are_saved_and_not_overridden(self):
        from PySide6.QtWidgets import QHeaderView
        from qt_app import COLUMNS
        w=self.window;index=COLUMNS.index('character')
        self.assertEqual(w.table.horizontalHeader().sectionResizeMode(index),QHeaderView.ResizeMode.Interactive)
        w.table.horizontalHeader().resizeSection(index,333)
        self.app.processEvents()
        self.assertEqual(w.settings['column_widths']['character'],333)
        w.resize(1700,640);self.app.processEvents();self.app.processEvents()
        self.assertEqual(w.table.columnWidth(index),333)
        w.save()
        saved=json.loads(w.settings_path.read_text())
        self.assertEqual(saved['column_widths']['character'],333)
    def test_fit_columns_resets_manual_override(self):
        w=self.window;w.table.horizontalHeader().resizeSection(1,333)
        self.assertTrue(w.custom_columns)
        w.fit_columns()
        self.assertFalse(w.custom_columns)
        self.assertNotIn('column_widths',w.settings)

    def test_account_profiles_are_saved_per_character_and_written_to_bot_ini(self):
        w=self.window
        w.row_widgets['Character One']['automatic'].setCurrentText('Grail of Might')
        w.row_widgets['Character One']['manual'].setCurrentText('Armor of Salvation')
        self.assertEqual(w.account_supply_profiles['Character One']['automatic_profile'],'Grail of Might')
        self.assertEqual(w.account_supply_profiles['Character One']['manual_profile'],'Armor of Salvation')
        import configparser
        ini=configparser.ConfigParser()
        ini.read(w.exe.parent/'Config'/'supply.ini')
        self.assertEqual(ini['Character:Character One']['AutomaticProfile'],'Grail of Might')
        self.assertEqual(ini['Character:Character One']['ManualProfile'],'Armor of Salvation')

    def test_buy_cons_is_available_during_active_session_and_queues_character_request(self):
        w=self.window;name='Character One'
        w.sessions[name]=w.session(FakeOwnedProcess(None),'run')
        w.update_buycons_button(name)
        self.assertTrue(w.row_widgets[name]['buycons'].isEnabled())
        w.request_supply_purchase(name)
        request=w.exe.parent/'Config'/('supply.manual.'+w.supply_file_key(name)+'.request')
        self.assertTrue(request.exists())
        self.assertIn(name,w.buy_cons_pending)
        self.assertFalse(w.row_widgets[name]['buycons'].isEnabled())

    def test_fiber_farm_plays_the_accounts_ranger_from_the_character_manager(self):
        import configparser
        w=self.window;key='Character One'
        w.row_widgets[key]['farm'].setCurrentText('Fiber')
        self.assertEqual(w.row_character(key),'')
        self.assertIn('No Ranger',w.tree.set(key,'character'))
        self.assertTrue(w.add_character('Ranger Two','Ranger',key))
        self.assertEqual(w.row_character(key),'Ranger Two')
        self.assertEqual(w.tree.set(key,'character'),'Ranger Two')
        self.assertEqual(w.row_character(key,'Ministerial'),'Character One')
        from qt_app import parse_characters,read_ini_text
        self.assertIn('Ranger Two',parse_characters(read_ini_text(w.characters_ini())[0]))
        self.assertEqual(w.settings['characters']['Ranger Two'],{'profession':'Ranger','account':key})
        farms=configparser.ConfigParser();farms.optionxform=str;farms.read(w.exe.parent/'Config'/'farms.ini')
        self.assertEqual(dict(farms['Farms']),{'Character One':'Ministerial','Ranger Two':'Fiber'})
        supply=configparser.ConfigParser();supply.read(w.exe.parent/'Config'/'supply.ini')
        self.assertIn('Character:Ranger Two',supply)
        self.assertEqual(supply['Fiber']['Threshold'],'6500')
        self.assertEqual(w.character_table.rowCount(),2)

    def test_ministerial_character_is_selectable_but_other_farms_are_locked(self):
        w=self.window;key='Character One'
        w.add_character('Second Character','Ranger',key)
        character=w.row_widgets[key]['character']
        self.assertTrue(character.isEnabled())
        character.setCurrentText('Second Character')
        self.assertEqual(w.row_character(key),'Second Character')
        self.assertEqual(w.account_record(key)['characters']['Ministerial'],'Second Character')
        w.row_widgets[key]['farm'].setCurrentText('Fiber')
        self.assertFalse(character.isEnabled())
        # The account's Ranger remains the selected Fiber character even though
        # the Character control is locked while a profession-specific farm is active.
        self.assertEqual(w.row_character(key),'Second Character')
        w.row_widgets[key]['farm'].setCurrentText('Vaettir')
        self.assertFalse(character.isEnabled())

    def test_bulk_account_setup_writes_login_sections_without_plaintext_passwords(self):
        w=self.window
        w.write_new_accounts([{'character':'New Account Char','email':'new@example.com',
            'gw_exe':str(Path(self.temp.name)/'Gw.exe'),'protected_password':'{DPAPI}protected'}])
        from qt_app import parse_characters,read_ini_text
        sections=parse_characters(read_ini_text(w.characters_ini())[0])
        self.assertIn('New Account Char',sections)
        saved=read_ini_text(w.characters_ini())[0]
        self.assertIn('Email=new@example.com',saved)
        self.assertIn('Pwd={DPAPI}protected',saved)
        self.assertNotIn('plaintext',saved)

    def test_farm_options_dialog_saves_pcons_and_farm_options(self):
        import configparser
        from PySide6.QtCore import Qt
        from qt_app import FarmOptionsDialog,DEFAULT_PCONS
        w=self.window
        self.assertEqual(w.farm_options_button.text(),'Farm Options')
        dialog=FarmOptionsDialog(w,w.settings.get('supply',{}),w.settings.get('farm_options',{}),w.save_farm_options)
        # Defaults follow the gw-suite bots' saved settings.
        self.assertTrue(dialog.event_only.isChecked())
        self.assertTrue(dialog.checks['Vaettir']['salvage_loot'].isChecked())
        self.assertFalse(dialog.checks['Vaettir']['keep_glacial_stones'].isChecked())
        self.assertTrue(dialog.checks['Fiber']['salvage_dragon_root'].isChecked())
        self.assertEqual(dialog.golds['Fiber'].currentText(),'Salvage')
        self.assertEqual(sorted(dialog.pcons()),sorted(DEFAULT_PCONS))
        dialog.set_all_pcons(Qt.CheckState.Unchecked)
        for item in dialog.pcon_items():
            if item.text().strip() in ('Slice of Pumpkin Pie','Hard Apple Cider'):item.setCheckState(Qt.CheckState.Checked)
        dialog.fiber_threshold.setValue(7000);dialog.checks['Vaettir']['keep_glacial_stones'].setChecked(True)
        dialog.golds['Vaettir'].setCurrentText('Store')
        dialog.save_settings()
        options=w.settings['farm_options']
        self.assertEqual(options['pcons'],[28436,28435])
        self.assertTrue(options['Vaettir']['keep_glacial_stones']);self.assertEqual(options['Vaettir']['golds'],'Store')
        self.assertEqual(w.settings['supply']['fiber_scroll_threshold'],7000)
        supply=configparser.ConfigParser();supply.read(w.exe.parent/'Config'/'supply.ini')
        self.assertEqual(supply['Pcons']['PickUp'],'28436,28435')
        self.assertEqual(supply['Vaettir']['EventItemsOnly'],'true')
        self.assertEqual(supply['Vaettir']['KeepGlacialStones'],'true')
        self.assertEqual(supply['Vaettir']['Golds'],'Store')
        self.assertEqual(supply['Fiber']['SalvageDragonRoot'],'true')
        self.assertEqual(supply['Fiber']['Threshold'],'7000')

    def test_event_items_only_needs_a_pcon(self):
        from PySide6.QtCore import Qt
        from qt_app import FarmOptionsDialog
        w=self.window
        dialog=FarmOptionsDialog(w,{},{},w.save_farm_options);dialog.set_all_pcons(Qt.CheckState.Unchecked)
        with patch('qt_app.QMessageBox.warning') as warning:dialog.save_settings()
        warning.assert_called_once();self.assertNotIn('farm_options',w.settings)

    def test_farm_options_normalize(self):
        from qt_app import normalize_farm_options
        result=normalize_farm_options({'pcons':['28436',99,'x',28436],'Vaettir':{'event_items_only':0,'golds':'Melt'}})
        self.assertEqual(result['pcons'],[28436])
        self.assertFalse(result['Vaettir']['event_items_only']);self.assertEqual(result['Vaettir']['golds'],'Salvage')
        self.assertTrue(normalize_farm_options(None)['Vaettir']['event_items_only'])

    def test_reconnect_keeps_saved_farm_when_it_plays_the_running_character(self):
        w=self.window;key='Character One'
        w.row_widgets[key]['farm'].setCurrentText('Ministerial')
        w.settings.setdefault('characters',{})['Character One']={'profession':'Assassin','account':key}
        w.broker=Mock();w.broker.call.return_value=[{'active':True,'exe':str(w.exe),'character':'Character One','identifier':'x','pid':1}]
        with patch('qt_app.RemoteProcess'):w.reconnect()
        self.assertEqual(w.account_record(key)['farm'],'Ministerial')

    def test_vaettir_farm_plays_the_accounts_assassin(self):
        import configparser
        w=self.window;key='Character One'
        w.row_widgets[key]['farm'].setCurrentText('Vaettir')
        self.assertIn('No Assassin',w.tree.set(key,'character'))
        w.set_profession('Character One','Assassin')
        self.assertEqual(w.row_character(key),'Character One')
        w.add_character('Ranger Two','Ranger',key)
        self.assertEqual(w.row_character(key,'Fiber'),'Ranger Two')
        farms=configparser.ConfigParser();farms.optionxform=str;farms.read(w.exe.parent/'Config'/'farms.ini')
        # One character serves Ministerial and Vaettir; the selected farm wins.
        self.assertEqual(dict(farms['Farms']),{'Character One':'Vaettir','Ranger Two':'Fiber'})

    def test_rows_follow_the_saved_account_order(self):
        import json as _json
        from qt_app import Desktop,account_key
        folder=Path(self.temp.name)
        (folder/'Config'/'characters.ini').write_text('[Alpha]\nEmail = a@example.com\n[Bravo]\nEmail = b@example.com\n[Charlie]\nEmail = c@example.com\n[Ranger B]\nEmail = b@example.com\n')
        a,b,c=(account_key(e+'@example.com','') for e in 'abc')
        (folder/'EncounterHub'/'settings.json').write_text(_json.dumps({
            'bot_path':str(folder/'Encounter_ReBuilt.exe'),'account_order':[c,b],
            'accounts':{c:{'label':'Account 6'},b:{'label':'Account 6'},a:{'label':'Account 8'}}}))
        with patch.dict(os.environ,{'LOCALAPPDATA':str(folder)}):window=Desktop('test',start_supervisor=False)
        try:
            self.assertEqual(list(window.rows),[c,b,a])
            self.assertEqual([window.rows[k] for k in (c,b,a)],[0,1,2])
            self.assertEqual([window.account_label(k) for k in (c,b,a)],
                             ['Account 1','Account 2','Account 3'])
            self.assertEqual(window.account_characters[b],['Bravo','Ranger B'])
            self.assertEqual(window.character_table.item(0,0).text(),'Charlie')
        finally:
            window.monitor_stop.set();window.monitor_worker.join(timeout=5);window.restarting=True;window.close();self.app.processEvents()

    def test_changing_profession_changes_the_farm_character(self):
        w=self.window;key='Character One'
        w.add_character('Ranger Two','Warrior',key)
        w.row_widgets[key]['farm'].setCurrentText('Fiber')
        self.assertEqual(w.row_character(key),'')
        w.set_profession('Ranger Two','Ranger')
        self.assertEqual(w.row_character(key),'Ranger Two')

    def test_invalid_or_duplicate_character_is_not_added(self):
        w=self.window;key='Character One'
        self.assertFalse(w.add_character('Bad]Name','Ranger',key))
        self.assertFalse(w.add_character('Character One','Ranger',key))
        self.assertEqual(w.account_characters[key],['Character One'])

    def test_remove_character_keeps_the_last_login(self):
        w=self.window;key='Character One'
        w.add_character('Ranger Two','Ranger',key)
        self.assertTrue(w.remove_character(key,'Character One',confirm=False))
        self.assertEqual(w.account_characters[key],['Ranger Two'])
        self.assertFalse(w.remove_character(key,'Ranger Two',confirm=False))
        self.assertEqual(w.row_character(key,'Ministerial'),'Ranger Two')
        from qt_app import parse_characters,read_ini_text
        self.assertEqual(list(parse_characters(read_ini_text(w.characters_ini())[0])),['Ranger Two'])

    def test_launch_uses_the_farm_character_and_locks_the_farm(self):
        w=self.window;key='Character One'
        w.broker=Mock();w.broker.call.return_value={'identifier':'abc','pid':99}
        with patch('qt_app.RemoteProcess',return_value=FakeOwnedProcess(None)):w.launch([key])
        w.broker.call.assert_called_once_with('launch',exe=str(w.exe.resolve()),character='Character One')
        self.assertEqual(w.sessions[key]['character'],'Character One')
        self.assertFalse(w.row_widgets[key]['farm'].isEnabled())
        w.row_widgets[key]['farm'].setCurrentText('Fiber')
        self.assertEqual(w.account_record(key)['farm'],'Ministerial')

    def test_migration_keeps_main_character_and_marks_fiber_choice_as_ranger(self):
        import json as _json
        from qt_app import Desktop,account_key
        folder=Path(self.temp.name)
        (folder/'Config'/'characters.ini').write_text('[Zed Main]\nEmail = one@example.com\n[Aim Ranger]\nEmail = one@example.com\n')
        key=account_key('one@example.com','Zed Main')
        (folder/'EncounterHub'/'settings.json').write_text(_json.dumps({'bot_path':str(folder/'Encounter_ReBuilt.exe'),'selected':['Zed Main'],
            'account_supply_profiles':{'Zed Main':{'automatic_profile':'Grail of Might','manual_profile':'Res Scrolls'}},
            'accounts':{key:{'farm':'Fiber','characters':{'Fiber':'Aim Ranger'}}}}))
        with patch.dict(os.environ,{'LOCALAPPDATA':str(folder)}):window=Desktop('test',start_supervisor=False)
        try:
            self.assertEqual(list(window.rows),[key])
            self.assertEqual(window.account_characters[key],['Aim Ranger','Zed Main'])
            self.assertEqual(window.character_profession('Aim Ranger'),'Ranger')
            self.assertEqual(window.row_character(key),'Aim Ranger')
            self.assertEqual(window.row_character(key,'Ministerial'),'Zed Main')
            self.assertEqual(window.row_widgets[key]['automatic'].currentText(),'Grail of Might')
            self.assertEqual(window.checked,{key})
        finally:
            window.monitor_stop.set();window.monitor_worker.join(timeout=5);window.restarting=True;window.close();self.app.processEvents()

    def test_fiber_without_ranger_is_not_launched(self):
        w=self.window;key='Character One';w.broker=Mock()
        w.row_widgets[key]['farm'].setCurrentText('Fiber')
        w.launch([key])
        w.broker.call.assert_not_called()
        self.assertIn('No Ranger',w.tree.set(key,'status'))

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

class Accounts(unittest.TestCase):
    def test_bulk_add_rejects_duplicate_existing_and_batch_login_emails(self):
        from qt_app import validate_new_account_emails
        existing={'Main':{'email':'six@example.com'}}
        with self.assertRaisesRegex(ValueError,'already used'):
            validate_new_account_emails([{'email':'SIX@example.com'}],existing)
        with self.assertRaisesRegex(ValueError,'more than once'):
            validate_new_account_emails([{'email':'seven@example.com'},{'email':' SEVEN@example.com '}],existing)
        validate_new_account_emails([{'email':'seven@example.com'},{'email':'eight@example.com'}],existing)

    def test_new_accounts_append_after_existing_account_order(self):
        from qt_app import append_account_order,account_key
        existing={'Alpha':{'email':'a@example.com'},'Bravo':{'email':'b@example.com'}}
        records=[{'character':'Charlie','email':'c@example.com'},
                 {'character':'Delta','email':'d@example.com'}]
        order=append_account_order([],existing,records)
        self.assertEqual(order,[account_key('a@example.com','Alpha'),
                                account_key('b@example.com','Bravo'),
                                account_key('c@example.com','Charlie'),
                                account_key('d@example.com','Delta')])
        self.assertEqual(append_account_order(order,existing,records),order)

    def test_dpapi_password_round_trip_preserves_unicode_and_special_characters(self):
        if sys.platform!='win32':self.skipTest('Windows DPAPI required')
        import ctypes
        from ctypes import wintypes
        from qt_app import protect_account_password
        password="z'0dr£J25'-g"
        protected=protect_account_password(password)
        self.assertTrue(protected.startswith('{DPAPI}'))
        raw=bytes.fromhex(protected[len('{DPAPI}'):])
        class Blob(ctypes.Structure):
            _fields_=[('size',wintypes.DWORD),('data',ctypes.c_void_p)]
        source=Blob(len(raw),ctypes.cast(ctypes.create_string_buffer(raw),ctypes.c_void_p));target=Blob()
        api=ctypes.windll.crypt32.CryptUnprotectData
        api.argtypes=[ctypes.POINTER(Blob),ctypes.c_void_p,ctypes.c_void_p,ctypes.c_void_p,ctypes.c_void_p,wintypes.DWORD,ctypes.POINTER(Blob)]
        api.restype=wintypes.BOOL
        self.assertTrue(api(ctypes.byref(source),None,None,None,None,1,ctypes.byref(target)))
        try:self.assertEqual(ctypes.string_at(target.data,target.size).decode('utf-8'),password)
        finally:ctypes.windll.kernel32.LocalFree(target.data)

    def test_characters_sharing_an_email_form_one_account(self):
        from qt_app import parse_characters,group_accounts
        text='[Main A]\nEmail = one@example.com\n[Ranger A]\nemail=ONE@example.com\n[Other]\nEmail = two@example.com\n[Loose]\n'
        groups=dict(group_accounts(parse_characters(text)))
        self.assertIn(['Main A','Ranger A'],list(groups.values()))
        self.assertIn(['Other'],list(groups.values()))
        self.assertEqual(groups['Loose'],['Loose'])
        self.assertNotIn('one@example.com',' '.join(groups))
    def test_clone_keeps_login_lines_and_utf16_encoding(self):
        from qt_app import clone_character_section,parse_characters,read_ini_text
        with tempfile.TemporaryDirectory() as directory:
            path=Path(directory)/'characters.ini'
            path.write_bytes('[Main]\r\nEmail = one@example.com\r\nPwd = {SEC}ABC\r\nFilePath = C:\\GW\\Gw.exe\r\n'.encode('utf-16'))
            self.assertTrue(clone_character_section(path,'Main','Ranger'))
            self.assertFalse(clone_character_section(path,'Main','Ranger'))
            text,encoding=read_ini_text(path)
            self.assertEqual(encoding,'utf-16')
            sections=parse_characters(text)
            self.assertEqual(sections['Ranger'],sections['Main'])

class StepUsesSessionCharacter(unittest.TestCase):
    def test_bot_character_list_is_matched_by_session_character(self):
        import app_main
        hub=Mock();reports=[];hub.report=lambda *args:reports.append(args)
        native=hub.native;native.u.IsWindow.return_value=True;native.title.return_value='Encounter Re:Built'
        native.children.return_value=[7];native.kind.return_value='ComboBox'
        def text(handle,message=0xD,index=None):
            return {0:'1 - Main',1:'2 - Ranger'}.get(index,'') if message==0x148 else ''
        native.text.side_effect=text
        native.u.PostMessageW.return_value=True
        process=Mock();process.poll.return_value=None;process.games.return_value=[]
        session=dict(process=process,phase='select',deadline=time.monotonic()+60,pending=None,window=5,controls=None,next_games=0,stopping=False,character='Ranger')
        app_main.Hub.step(hub,'account-row',session)
        native.u.PostMessageW.assert_called_once_with(7,0x14E,1,0)
        self.assertEqual(session['phase'],'start')

class MinimizeOnStart(unittest.TestCase):
    def test_new_bot_minimized_once(self):
        from app_main import minimize_started_bot
        native=Mock();native.u.ShowWindowAsync.return_value=True
        session={'minimize_on_start':True,'minimized':False}
        minimize_started_bot(native,123,session);minimize_started_bot(native,123,session)
        native.u.ShowWindowAsync.assert_called_once_with(123,6)
    def test_reconnected_bot_is_not_minimized(self):
        from app_main import minimize_started_bot
        native=Mock()
        minimize_started_bot(native,123,{'minimize_on_start':False,'minimized':False})
        native.u.ShowWindowAsync.assert_not_called()

class RecoveryStart(unittest.TestCase):
    def native(self):
        native=Mock();native.kind.return_value='ComboBox';native.text.return_value='1 - Char';native.click.return_value=True
        return native
    def test_one_attempt_waits_two_minutes(self):
        from app_main import recover_start
        native=self.native();session={}
        status=recover_start(native,'Char',session,[12],{'Start':34},now=100)
        self.assertIn('Recovery Start sent',status);self.assertEqual(session['deadline'],220)
        self.assertEqual(session['phase'],'recovering')
        self.assertIn('did not confirm',recover_start(native,'Char',session,[12],{'Start':34},now=221))
        native.click.assert_called_once_with(34)
    def test_pause_resume_are_never_clicked(self):
        from app_main import recover_start
        native=self.native()
        recover_start(native,'Char',{},[12],{'Pause':34,'Resume':56},now=100)
        native.click.assert_not_called()
    def test_wrong_character_is_not_started(self):
        from app_main import recover_start
        native=self.native();native.text.return_value='Other Char'
        self.assertIn('does not match',recover_start(native,'Char',{},[12],{'Start':34},now=100))
        native.click.assert_not_called()
    def test_disabled_start_does_not_count_as_sent(self):
        from app_main import recover_start
        native=self.native();native.click.return_value=False;session={}
        self.assertIn('disabled',recover_start(native,'Char',session,[12],{'Start':34},now=100))
        self.assertNotIn('recovery_attempted',session)

class StorageCounter(unittest.TestCase):
    def test_count_label_is_chosen_instead_of_per_run(self):
        from app_main import storage_counter_control
        native=Mock();native.kind.return_value='Static'
        native.text.side_effect=lambda h:{1:'– Put in Storage',2:'120',3:'2'}[h]
        native.u.GetDlgCtrlID.side_effect=lambda h:{1:100,2:101,3:102}[h]
        native.rect.side_effect=lambda h:{1:(21,350,140,370),2:(173,350,325,370),3:(325,350,477,370)}[h]
        self.assertEqual(storage_counter_control(native,[1,3,2]),2)
    def test_geometry_fallback_chooses_leftmost_count(self):
        from app_main import storage_counter_control
        native=Mock();native.kind.return_value='Static';native.u.GetDlgCtrlID.return_value=0
        native.text.side_effect=lambda h:{1:'– Put in Storage',2:'1,234',3:'3.2'}[h]
        native.rect.side_effect=lambda h:{1:(21,350,140,370),2:(173,350,325,370),3:(325,350,477,370)}[h]
        self.assertEqual(storage_counter_control(native,[1,2,3]),2)
    def test_missing_stat_is_not_reported_as_zero(self):
        from app_main import storage_counter_control
        native=Mock();native.kind.return_value='Static';native.text.return_value='Other statistic'
        self.assertIsNone(storage_counter_control(native,[1]))
