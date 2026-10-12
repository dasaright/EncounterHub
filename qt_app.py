"""Native Qt desktop, matching TacoBot's colors and control treatment."""
import ctypes
import json
import os
from pathlib import Path
import queue
import subprocess
import sys
import threading
import time
from PySide6.QtCore import Qt, QTimer, QSignalBlocker
from PySide6.QtGui import QIcon, QAction
from PySide6.QtWidgets import (QApplication,QMainWindow,QWidget,QVBoxLayout,QHBoxLayout,QLabel,QPushButton,
    QCheckBox,QTableWidget,QTableWidgetItem,QHeaderView,QAbstractItemView,QFileDialog,QMessageBox)
import app_main as engine
from supervisor import ensure, RemoteProcess, command_line

# TacoBot's exact current desktop stylesheet, committed in this repo.
try:
    from qt_style import STYLE
except ImportError:
    STYLE='QWidget {background:#14171c;color:#dce5ef;font-family:"Segoe UI";} QPushButton {background:#202731;border-radius:6px;padding:7px;} QPushButton:hover {background:#2a3741;} QHeaderView::section {background:#162337;padding:7px;} QTableWidget{background:#1b2027;}'

COLUMNS=('check','character','status','command','render','ontop','pause','resume','stop','launch')
CAPTIONS=('Select','Character','Bot Status','Command','Disable Rendering','Always on Top','Pause','Resume','Stop','Launch')

class QtDialogs:
    @staticmethod
    def askyesno(title,text):return QMessageBox.question(None,title,text)==QMessageBox.StandardButton.Yes
    @staticmethod
    def showinfo(title,text):QMessageBox.information(None,title,text)
    @staticmethod
    def showwarning(title,text):QMessageBox.warning(None,title,text)
    @staticmethod
    def showerror(title,text):QMessageBox.critical(None,title,text)

class TableAdapter:
    def __init__(self,desktop):self.desktop=desktop;self.hidden={}
    def get_children(self):return tuple(self.desktop.rows)
    def exists(self,name):return name in self.desktop.rows
    def set(self,name,column,value=None):
        if column not in COLUMNS:
            if value is not None:self.hidden[(name,column)]=str(value)
            return self.hidden.get((name,column),'')
        row=self.desktop.rows[name];index=COLUMNS.index(column)
        item=self.desktop.table.item(row,index)
        if value is None:return item.text() if item else ''
        if not item:item=QTableWidgetItem();self.desktop.table.setItem(row,index,item)
        item.setText(str(value));return str(value)

class Desktop(QMainWindow):
    # Reuse only background controller behavior, not Tk layout or callbacks.
    step=engine.Hub.step
    monitor=engine.Hub.monitor
    sync_options=engine.Hub.sync_options
    report=engine.Hub.report
    command=engine.Hub.command
    stop=engine.Hub.stop
    save=engine.Hub.save
    show_bots=engine.Hub.show
    selected=engine.Hub.selected

    def __init__(self,status='Ready',start_supervisor=True):
        super().__init__();engine.messagebox=QtDialogs
        self.setWindowTitle('Encounter Hub '+engine.VERSION);self.resize(1400,640);self.setMinimumSize(900,460)
        self.closing=False;self.restarting=False;self.busy_update=False;self.update_available=False;self.update_commit=None
        self.native=engine.Native() if sys.platform=='win32' else None
        self.sessions={};self.retired=[];self.checked=set();self.rows={};self.row_widgets={}
        self.monitor_events=queue.Queue();self.requests=queue.Queue();self.monitor_stop=threading.Event();self.events=queue.Queue()
        self.data=Path(os.environ.get('LOCALAPPDATA',str(Path.home())))/'EncounterHub';self.data.mkdir(parents=True,exist_ok=True)
        self.settings_path=self.data/'settings.json'
        try:self.settings=json.loads(self.settings_path.read_text())
        except (OSError,ValueError):self.settings={}
        self.checked=set(self.settings.get('selected',[]))
        self.exe=Path(self.settings.get('bot_path',str(Path(__file__).parent/'Encounter_ReBuilt.exe')))
        self.broker=ensure() if start_supervisor else None
        central=QWidget();self.setCentralWidget(central);outer=QVBoxLayout(central);outer.setContentsMargins(16,16,16,16);outer.setSpacing(12)
        top=QHBoxLayout();outer.addLayout(top)
        title=QLabel('Encounter Hub');title.setStyleSheet('font-size:24px;font-weight:600;color:#52d4ba;');top.addWidget(title);top.addStretch()
        updates=QVBoxLayout();top.addLayout(updates)
        self.check_button=QPushButton('Check for Updates');self.check_button.clicked.connect(self.check_update);updates.addWidget(self.check_button)
        self.update_button=QPushButton('Update Now');self.update_button.setProperty('primary',True);self.update_button.setEnabled(False);self.update_button.clicked.connect(self.update_now);updates.addWidget(self.update_button)
        toolbar=QHBoxLayout();outer.addLayout(toolbar)
        for text,callback in [('Choose Bot...',self.choose),('Select All',lambda:self.select_all(True)),('Clear Selection',lambda:self.select_all(False))]:
            button=QPushButton(text);button.clicked.connect(callback);toolbar.addWidget(button)
        toolbar.addStretch();self.path_label=QLabel(str(self.exe));self.path_label.setTextInteractionFlags(Qt.TextInteractionFlag.TextSelectableByMouse);toolbar.addWidget(self.path_label)
        self.table=QTableWidget(0,len(COLUMNS));self.table.setHorizontalHeaderLabels(CAPTIONS);self.table.setAlternatingRowColors(True)
        self.table.setEditTriggers(QAbstractItemView.EditTrigger.NoEditTriggers);self.table.setSelectionMode(QAbstractItemView.SelectionMode.NoSelection)
        self.table.verticalHeader().setVisible(False);self.table.verticalHeader().setDefaultSectionSize(46)
        self.table.setShowGrid(False);outer.addWidget(self.table,1);self.tree=TableAdapter(self)
        header=self.table.horizontalHeader();header.setMinimumSectionSize(60)
        header.setSectionResizeMode(QHeaderView.ResizeMode.Interactive)
        header.setStretchLastSection(False)
        self.resizing_columns=False
        saved=self.settings.get('column_widths',{})
        self.custom_columns=bool(saved)
        defaults=(60,220,210,245,150,140,82,82,82,82)
        self.resizing_columns=True
        for index,key in enumerate(COLUMNS):
            width=saved.get(key,defaults[index]) if isinstance(saved,dict) else defaults[index]
            header.resizeSection(index,max(self.minimum_column(index),int(width)))
        self.resizing_columns=False
        self.width_save=QTimer(self);self.width_save.setSingleShot(True);self.width_save.timeout.connect(self.save)
        header.sectionResized.connect(self.column_resized)
        fit=QPushButton('Fit Columns');fit.clicked.connect(self.fit_columns);toolbar.insertWidget(3,fit)
        if not self.custom_columns:QTimer.singleShot(0,self.auto_fit)
        footer=QHBoxLayout();outer.addLayout(footer)
        for text,callback in [('Launch Selected',self.launch),('Pause Selected',lambda:self.command('Pause')),('Resume Selected',lambda:self.command('Resume')),('Stop Selected',self.stop),('Trade Mode',lambda:self.command('Trade Mode')),('Open Lockboxes',lambda:self.command('Open Lockboxes')),('Show Selected',self.show_bots)]:
            button=QPushButton(text);button.clicked.connect(callback);footer.addWidget(button)
        footer.addStretch()
        self.notice=QLabel(status);self.notice.setWordWrap(True);outer.addWidget(self.notice)
        self.load_names()
        if self.broker:self.reconnect()
        self.monitor_worker=threading.Thread(target=self.monitor,daemon=True);self.monitor_worker.start()
        self.timer=QTimer(self);self.timer.timeout.connect(self.tick);self.timer.start(100)
        if start_supervisor and not self.exe.is_file():QTimer.singleShot(0,self.choose)
        menu=self.menuBar().addMenu('Application')
        shortcut=QAction('Create Desktop Shortcut',self);shortcut.triggered.connect(self.shortcut);menu.addAction(shortcut)

    def minimum_column(self,index):
        if COLUMNS[index] in ('character','status','command'):return 100
        return max(60,self.fontMetrics().horizontalAdvance(CAPTIONS[index])+24)

    def column_resized(self,index,old,width):
        if self.resizing_columns:return
        self.resizing_columns=True
        self.table.horizontalHeader().resizeSection(index,max(self.minimum_column(index),width))
        self.resizing_columns=False
        self.custom_columns=True
        self.settings['column_widths']={key:self.table.columnWidth(i) for i,key in enumerate(COLUMNS)}
        self.width_save.start(300)

    def fit_columns(self):
        # Explicit reset. Normal window resizing never overrides custom widths.
        self.custom_columns=False
        available=self.table.viewport().width()
        fixed={i:max(self.minimum_column(i),82 if COLUMNS[i] in ('pause','resume','stop','launch') else self.minimum_column(i)) for i in range(len(COLUMNS)) if COLUMNS[i] not in ('character','status','command')}
        remainder=max(300,available-sum(fixed.values()))
        flexible={1:max(100,round(remainder*.32)),2:max(100,round(remainder*.30))}
        flexible[3]=max(100,remainder-flexible[1]-flexible[2])
        self.resizing_columns=True
        for index,width in {**fixed,**flexible}.items():self.table.setColumnWidth(index,width)
        self.resizing_columns=False
        self.settings.pop('column_widths',None)
        self.width_save.start(300)

    def auto_fit(self):
        if not self.custom_columns:self.fit_columns()

    def resizeEvent(self,event):
        super().resizeEvent(event)
        if hasattr(self,'table') and not self.custom_columns:QTimer.singleShot(0,self.auto_fit)

    def load_names(self):
        import re
        try:
            raw=(self.exe.parent/'Config'/'characters.ini').read_bytes()
            text=raw.decode('utf-16') if raw.startswith((b'\xff\xfe',b'\xfe\xff')) else raw.decode('utf-8-sig',errors='replace')
            names=sorted(set(re.findall(r'^\s*\[([^\]\r\n]+)\]\s*$',text,re.M)))
        except OSError:names=[]
        self.table.setRowCount(0);self.rows.clear();self.row_widgets.clear()
        for name in names:self.add_row(name)

    def add_row(self,name):
        if name in self.rows:return
        row=self.table.rowCount();self.table.insertRow(row);self.rows[name]=row
        self.tree.set(name,'character',name);self.tree.set(name,'status','Ready')
        widgets={}
        for key in ('check','render','ontop'):
            checkbox=QCheckBox();holder=QWidget();layout=QHBoxLayout(holder);layout.setContentsMargins(4,0,4,0);layout.setAlignment(Qt.AlignmentFlag.AlignCenter);layout.addWidget(checkbox)
            self.table.setCellWidget(row,COLUMNS.index(key),holder);widgets[key]=checkbox
            checkbox.setChecked(name in self.checked if key=='check' else False);checkbox.setEnabled(key=='check')
            checkbox.clicked.connect(lambda checked,k=key,n=name:self.checkbox(n,k,checked))
        for key in ('pause','resume','stop','launch'):
            button=QPushButton(key.title());button.setMinimumWidth(58);self.table.setCellWidget(row,COLUMNS.index(key),button);widgets[key]=button
            button.clicked.connect(lambda checked=False,k=key,n=name:self.row_action(n,k))
        self.row_widgets[name]=widgets

    def row_action(self,name,key):
        if key=='launch':self.launch([name])
        elif key=='stop':self.stop([name])
        else:self.command(key.title(),[name])

    def checkbox(self,name,key,checked):
        if key=='check':
            if checked:self.checked.add(name)
            else:self.checked.discard(name)
            self.save();return
        s=self.sessions.get(name)
        if not s or s['stopping'] or s['process'].poll() is not None:return
        self.row_widgets[name][key].setEnabled(False);self.requests.put(('option',name,s,(key,checked)))

    def select_all(self,checked):
        self.checked=set(self.rows) if checked else set()
        for widgets in self.row_widgets.values():
            with QSignalBlocker(widgets['check']):widgets['check'].setChecked(checked)
        self.save()

    def choose(self):
        if self.sessions and any(s['process'].members() for s in self.sessions.values()):
            QtDialogs.showinfo('Bot folder','Stop active owned sessions before changing the bot folder.');return
        filename,_=QFileDialog.getOpenFileName(self,'Select Encounter_ReBuilt.exe',str(self.exe.parent),'Encounter bot (Encounter_ReBuilt.exe)')
        if filename:self.exe=Path(filename);self.path_label.setText(filename);self.sessions.clear();self.load_names();self.save();self.reconnect()

    def session(self,process,phase='select'):
        return dict(process=process,phase=phase,deadline=time.monotonic()+90,pending=None,command_deadline=0,sent_at=0,window=None,controls=None,next_games=0,stopping=False,stop_phase=None,options={},option_requests={},next_options=0)

    def reconnect(self):
        for record in self.broker.call('snapshot'):
            if not record['active'] or os.path.normcase(record['exe'])!=os.path.normcase(str(self.exe.resolve())):continue
            name=record['character'];self.add_row(name)
            self.sessions[name]=self.session(RemoteProcess(self.broker,record['identifier'],record['pid']),'wait')
            self.sessions[name]['deadline']=time.monotonic()+300
            self.tree.set(name,'status','Reconnected to active owned session');self.tree.set(name,'pid',record['pid'])

    def launch(self,names=None):
        # Qt clicked passes a bool: interpret it as bulk launch.
        if isinstance(names,bool):names=None
        for name in self.selected() if names is None else names:
            s=self.sessions.get(name)
            if s and (s['stopping'] or s['process'].members()):continue
            try:
                record=self.broker.call('launch',exe=str(self.exe.resolve()),character=name)
                self.sessions[name]=self.session(RemoteProcess(self.broker,record['identifier'],record['pid']))
                self.tree.set(name,'status','Opening bot...');self.tree.set(name,'command','');self.tree.set(name,'pid',record['pid'])
            except OSError as exc:self.tree.set(name,'status',str(exc))

    def stop(self,names=None):
        if isinstance(names,bool):names=None
        return engine.Hub.stop(self,names)

    def tick(self):
        if self.closing:return
        try:
            while True:
                name,column,value=self.monitor_events.get_nowait()
                if name not in self.rows:continue
                if column in ('render','ontop'):
                    widget=self.row_widgets[name][column]
                    with QSignalBlocker(widget):widget.setChecked(value=='1')
                elif column in ('_render_enabled','_ontop_enabled'):self.row_widgets[name][column[1:-8]].setEnabled(bool(value))
                else:self.tree.set(name,column,value)
        except queue.Empty:pass
        try:
            while True:
                kind,value=self.events.get_nowait()
                if kind=='check':
                    self.busy_update=False;self.check_button.setEnabled(True)
                    self.update_commit=value.get('commit');self.update_available=value.get('available',False)
                    self.update_button.setEnabled(self.update_available);self.notice.setText(value['message'])
                elif kind=='installed':self.busy_update=False;self.notice.setText(value);self.restart()
                elif kind=='error':self.busy_update=False;self.check_button.setEnabled(True);self.update_button.setEnabled(self.update_available);self.notice.setText(value)
        except queue.Empty:pass

    def check_update(self):
        if self.busy_update:return
        self.busy_update=True;self.check_button.setEnabled(False);self.notice.setText('Checking GitHub for updates...')
        def work():
            try:
                from hub import api,remote_file,ROOT
                import hashlib
                commit=api('git/ref/heads/main')['object']['sha'];manifest=json.loads(remote_file('desktop-bundle.json',commit))
                available=any(not (ROOT/name).exists() or hashlib.sha256((ROOT/name).read_bytes()).hexdigest()!=digest for name,digest in manifest['files'].items())
                self.events.put(('check',{'commit':commit,'available':available,'message':'Update '+manifest['version']+' is ready. Click Update Now.' if available else 'You are up to date ('+manifest['version']+').'}))
            except Exception as exc:self.events.put(('error','Update check failed: '+str(exc)))
        threading.Thread(target=work,daemon=True).start()

    def update_now(self):
        if self.busy_update or not self.update_available:return
        self.busy_update=True;self.update_button.setEnabled(False);self.check_button.setEnabled(False);self.notice.setText('Installing update; active bots will keep running...')
        def work():
            try:self.events.put(('installed',engine.update_bundle(commit=self.update_commit)))
            except Exception as exc:self.events.put(('error','Update failed; installed version and active bots retained: '+str(exc)))
        self.update_worker=threading.Thread(target=work,daemon=False);self.update_worker.start()

    def restart(self):
        self.save();self.monitor_stop.set()
        def finish():
            if self.monitor_worker.is_alive():QTimer.singleShot(100,finish);return
            try:
                subprocess.Popen(command_line()+['--wait-pid',str(os.getpid())],creationflags=getattr(subprocess,'CREATE_NO_WINDOW',0))
            except OSError as exc:
                self.monitor_stop.clear();self.monitor_worker=threading.Thread(target=self.monitor,daemon=True);self.monitor_worker.start()
                self.notice.setText('Restart failed; bots remain running: '+str(exc));return
            self.restarting=True;self.close()
        finish()

    def shortcut(self):
        if not getattr(sys,'frozen',False):QtDialogs.showinfo('Shortcut','Install the executable build to pin Encounter Hub to your taskbar.');return
        executable=Path(sys.executable)
        desktop=Path(os.environ['USERPROFILE'])/'Desktop'/'Encounter Hub.lnk'
        script=self.data/'create_shortcut.vbs'
        quote=lambda s:'"'+str(s).replace('"','""')+'"'
        script.write_text('Set shell=CreateObject("WScript.Shell")\nSet link=shell.CreateShortcut('+quote(desktop)+')\nlink.TargetPath='+quote(executable)+'\nlink.WorkingDirectory='+quote(executable.parent)+'\nlink.IconLocation='+quote(str(executable)+',0')+'\nlink.Save\n')
        subprocess.run(['wscript.exe',str(script)],creationflags=getattr(subprocess,'CREATE_NO_WINDOW',0),check=True)
        self.notice.setText('Desktop shortcut created. Right-click the running taskbar icon → Pin to taskbar.')

    def closeEvent(self,event):
        if self.restarting:
            self.timer.stop();event.accept();return  # Supervisor continues owning live jobs.
        if self.closing:event.ignore();return
        event.ignore();self.closing=True;self.timer.stop();self.monitor_stop.set();self.save();self.setEnabled(False)
        def finish():
            if self.monitor_worker.is_alive() or (getattr(self,'update_worker',None) and self.update_worker.is_alive()):QTimer.singleShot(100,finish);return
            errors=[]
            try:
                # Includes all owned sessions even when a bot's row is absent.
                records=self.broker.call('snapshot') if self.broker else []
                for record in records:
                    if record['active']:self.broker.call('shutdown',identifier=record['identifier'])
                if any(record['active'] for record in (self.broker.call('snapshot') if self.broker else [])):
                    QTimer.singleShot(100,finish);return
                if self.broker:self.broker.call('exit')
            except OSError as exc:
                self.closing=False;self.setEnabled(True);self.notice.setText('Could not close owned sessions: '+str(exc));self.monitor_stop.clear();self.monitor_worker=threading.Thread(target=self.monitor,daemon=True);self.monitor_worker.start();self.timer.start(100);return
            self.restarting=True;self.close()
        finish()


def run(status):
    app=QApplication.instance() or QApplication(sys.argv)
    app.setApplicationName('Encounter Hub');app.setStyle('Fusion');app.setStyleSheet(STYLE)
    if sys.platform=='win32':ctypes.windll.shell32.SetCurrentProcessExplicitAppUserModelID('EncounterHub.Desktop')
    icon=Path(sys.executable).parent/'taco.ico'
    if icon.exists():app.setWindowIcon(QIcon(str(icon)))
    window=Desktop(status);window.show();app.exec()
