"""Encounter Hub GUI and original-bot button controller."""
import ctypes
from ctypes import wintypes as W
import json
import os
from pathlib import Path
import queue
import re
import subprocess
import threading
import time
import tkinter as tk
from tkinter import ttk, filedialog, messagebox

VERSION = '1.1.0'


def command_action(command, buttons):
    """Choose an idempotent action from the original bot's button captions."""
    if command == 'Resume':
        if 'Pause' in buttons:
            return None, 'Already running', True
        return 'Resume', 'Waiting to resume', False
    active = {'Trade Mode': 'Stop Trade Mode', 'Open Lockboxes': 'Stop Opening'}
    if command in active and active[command] in buttons:
        return None, 'Already in ' + command, True
    if 'Pause' in buttons:
        return 'Pause', 'Pausing after current run', False
    if 'Waiting for pause...' in buttons:
        return None, 'Waiting for current run to finish', False
    if command == 'Pause':
        for caption in ('Stop Opening', 'Stop Trade Mode'):
            if caption in buttons:
                return caption, 'Stopping active mode', False
        if 'Resume' in buttons:
            return None, 'Paused', True
        return None, 'Waiting for bot', False
    return command, 'Waiting for ' + command, False


def update_bundle(root=None):
    """Install the complete allowlisted launcher bundle, with rollback on failure."""
    import hashlib
    from hub import api, remote_file, ROOT
    root = ROOT if root is None else Path(root)
    commit = api('git/ref/heads/main')['object']['sha']
    manifest = json.loads(remote_file('bundle.json', commit))
    allowed = {'app_main.py', 'hub.py', 'Launch Hub.vbs', 'Launch Hub.cmd', 'update.json'}
    if manifest.get('format') != 1 or set(manifest.get('files', {})) != allowed:
        raise ValueError('Unsupported launcher bundle')
    payloads = {}
    for name, digest in manifest['files'].items():
        if not isinstance(digest, str) or not re.fullmatch('[0-9a-f]{64}', digest):
            raise ValueError('Invalid bundle hash')
        local = root / name
        if local.exists() and hashlib.sha256(local.read_bytes()).hexdigest() == digest:
            continue
        payload = remote_file(name, commit)
        if hashlib.sha256(payload).hexdigest() != digest:
            raise ValueError('Bundle hash mismatch: ' + name)
        if name.endswith('.py'): compile(payload, name, 'exec')
        payloads[name] = payload
    if not payloads: return 'Already up to date (' + manifest['version'] + ')'
    previous = {name: (root/name).read_bytes() if (root/name).exists() else None for name in payloads}
    installed = []
    try:
        for name, payload in payloads.items():
            target = root/name
            if previous[name] is not None: (root/(name+'.backup')).write_bytes(previous[name])
            temporary=root/(name+'.download'); temporary.write_bytes(payload)
            os.replace(temporary,target); installed.append(name)
    except Exception:
        for name in reversed(installed):
            if previous[name] is None: (root/name).unlink(missing_ok=True)
            else:
                temporary=root/(name+'.rollback');temporary.write_bytes(previous[name]);os.replace(temporary,root/name)
        raise
    return 'Updated complete launcher to ' + manifest['version']


class JobProcess:
    """Launch suspended, assign a private Windows Job, then resume.

    Job membership is kernel-maintained, so unrelated clients and reused PIDs
    cannot become owned clients. KILL_ON_JOB_CLOSE applies to descendants too.
    """
    def __init__(self, exe, args=()):
        launch_args = list(args)
        k = self.k = ctypes.WinDLL('kernel32', use_last_error=True)
        class STARTUP(ctypes.Structure):
            _fields_=[('cb',W.DWORD),('reserved',W.LPWSTR),('desktop',W.LPWSTR),('title',W.LPWSTR),
                      ('x',W.DWORD),('y',W.DWORD),('xs',W.DWORD),('ys',W.DWORD),('xc',W.DWORD),('yc',W.DWORD),
                      ('fill',W.DWORD),('flags',W.DWORD),('show',W.WORD),('reserved2',W.WORD),
                      ('reservedptr',ctypes.c_void_p),('stdin',W.HANDLE),('stdout',W.HANDLE),('stderr',W.HANDLE)]
        class INFO(ctypes.Structure):
            _fields_=[('process',W.HANDLE),('thread',W.HANDLE),('pid',W.DWORD),('tid',W.DWORD)]
        class BASIC(ctypes.Structure):
            _fields_=[('process_time',ctypes.c_int64),('job_time',ctypes.c_int64),('flags',W.DWORD),
                      ('min_ws',ctypes.c_size_t),('max_ws',ctypes.c_size_t),('active',W.DWORD),
                      ('affinity',ctypes.c_size_t),('priority',W.DWORD),('scheduling',W.DWORD)]
        class IO(ctypes.Structure):
            _fields_=[(n,ctypes.c_uint64) for n in ('read_ops','write_ops','other_ops','read_bytes','write_bytes','other_bytes')]
        class LIMIT(ctypes.Structure):
            _fields_=[('basic',BASIC),('io',IO),('process_mem',ctypes.c_size_t),('job_mem',ctypes.c_size_t),
                      ('peak_process',ctypes.c_size_t),('peak_job',ctypes.c_size_t)]
        signatures={
            'CreateJobObjectW':([ctypes.c_void_p,W.LPCWSTR],W.HANDLE),
            'SetInformationJobObject':([W.HANDLE,ctypes.c_int,ctypes.c_void_p,W.DWORD],W.BOOL),
            'AssignProcessToJobObject':([W.HANDLE,W.HANDLE],W.BOOL),
            'CreateProcessW':([W.LPCWSTR,W.LPWSTR,ctypes.c_void_p,ctypes.c_void_p,W.BOOL,W.DWORD,ctypes.c_void_p,W.LPCWSTR,ctypes.POINTER(STARTUP),ctypes.POINTER(INFO)],W.BOOL),
            'ResumeThread':([W.HANDLE],W.DWORD),
            'CloseHandle':([W.HANDLE],W.BOOL),
            'TerminateProcess':([W.HANDLE,W.UINT],W.BOOL),
            'TerminateJobObject':([W.HANDLE,W.UINT],W.BOOL),
            'WaitForSingleObject':([W.HANDLE,W.DWORD],W.DWORD),
            'GetExitCodeProcess':([W.HANDLE,ctypes.POINTER(W.DWORD)],W.BOOL),
            'QueryInformationJobObject':([W.HANDLE,ctypes.c_int,ctypes.c_void_p,W.DWORD,ctypes.POINTER(W.DWORD)],W.BOOL),
            'OpenProcess':([W.DWORD,W.BOOL,W.DWORD],W.HANDLE),
            'QueryFullProcessImageNameW':([W.HANDLE,W.DWORD,W.LPWSTR,ctypes.POINTER(W.DWORD)],W.BOOL),
        }
        for name,(args,result) in signatures.items():
            f=getattr(k,name);f.argtypes=args;f.restype=result
        self.job=k.CreateJobObjectW(None,None);self.handle=None;self.pid=None
        if not self.job:raise ctypes.WinError(ctypes.get_last_error())
        limit=LIMIT();limit.basic.flags=0x2000  # JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE
        if not k.SetInformationJobObject(self.job,9,ctypes.byref(limit),ctypes.sizeof(limit)):
            error=ctypes.WinError(ctypes.get_last_error());k.CloseHandle(self.job);self.job=None;raise error
        startup=STARTUP();startup.cb=ctypes.sizeof(startup);info=INFO()
        command=ctypes.create_unicode_buffer(subprocess.list2cmdline([str(exe), *launch_args]))
        if not k.CreateProcessW(str(exe),command,None,None,False,0x4,None,str(exe.parent),ctypes.byref(startup),ctypes.byref(info)):
            error=ctypes.WinError(ctypes.get_last_error());k.CloseHandle(self.job);self.job=None;raise error
        self.handle=info.process;self.pid=info.pid
        try:
            if not k.AssignProcessToJobObject(self.job,self.handle):raise ctypes.WinError(ctypes.get_last_error())
            if k.ResumeThread(info.thread)==0xFFFFFFFF:raise ctypes.WinError(ctypes.get_last_error())
        except Exception:
            k.TerminateProcess(self.handle,1);self.close();raise
        finally:k.CloseHandle(info.thread)

    def poll(self):
        if not self.handle:return 0
        if self.k.WaitForSingleObject(self.handle,0)==0x102:return None
        code=W.DWORD();self.k.GetExitCodeProcess(self.handle,ctypes.byref(code));return code.value

    def terminate(self):
        # Stop only the bot. The owned job remains tracked until hub exit.
        if self.handle and self.poll() is None:
            if not self.k.TerminateProcess(self.handle,1):raise ctypes.WinError(ctypes.get_last_error())

    def members(self):
        if not self.job:return []
        # JOBOBJECT_BASIC_PROCESS_ID_LIST has two DWORDs followed by ULONG_PTRs.
        count=64
        while count<=65536:
            buffer=ctypes.create_string_buffer(8+ctypes.sizeof(ctypes.c_size_t)*count)
            if self.k.QueryInformationJobObject(self.job,3,buffer,len(buffer),None):
                size=W.DWORD.from_buffer(buffer,4).value
                array=(ctypes.c_size_t*size).from_buffer(buffer,8)
                return list(array)
            if ctypes.get_last_error()!=234:raise ctypes.WinError(ctypes.get_last_error())
            count*=2
        raise RuntimeError('Too many owned processes')

    def games(self):
        games=[]
        for pid in self.members():
            if pid==self.pid:continue
            handle=self.k.OpenProcess(0x1000,False,pid)
            if not handle:continue
            try:
                buffer=ctypes.create_unicode_buffer(32768);size=W.DWORD(len(buffer))
                if self.k.QueryFullProcessImageNameW(handle,0,buffer,ctypes.byref(size)):
                    if Path(buffer.value).name.lower()=='gw.exe':games.append(pid)
            finally:self.k.CloseHandle(handle)
        return games

    def shutdown(self):
        if self.job and not self.k.TerminateJobObject(self.job,1):raise ctypes.WinError(ctypes.get_last_error())

    def close(self):
        if self.job:self.k.CloseHandle(self.job);self.job=None
        if self.handle:self.k.CloseHandle(self.handle);self.handle=None


class Native:
    def __init__(self):
        self.u = ctypes.WinDLL('user32', use_last_error=True)
        self.callback = ctypes.WINFUNCTYPE(W.BOOL, W.HWND, W.LPARAM)
        signatures = {
            'EnumWindows': ([self.callback, W.LPARAM], W.BOOL),
            'EnumChildWindows': ([W.HWND, self.callback, W.LPARAM], W.BOOL),
            'GetWindowThreadProcessId': ([W.HWND, ctypes.POINTER(W.DWORD)], W.DWORD),
            'GetClassNameW': ([W.HWND, W.LPWSTR, ctypes.c_int], ctypes.c_int),
            'SendMessageTimeoutW': ([W.HWND, W.UINT, W.WPARAM, W.LPARAM, W.UINT, W.UINT, ctypes.POINTER(ctypes.c_size_t)], W.LPARAM),
            'PostMessageW': ([W.HWND, W.UINT, W.WPARAM, W.LPARAM], W.BOOL),
            'IsWindowEnabled': ([W.HWND], W.BOOL),
            'ShowWindow': ([W.HWND, ctypes.c_int], W.BOOL),
            'SetForegroundWindow': ([W.HWND], W.BOOL),
        }
        for name, (args, result) in signatures.items():
            f = getattr(self.u, name); f.argtypes = args; f.restype = result

    def text(self, handle, message=0xD, index=None):
        buffer = ctypes.create_unicode_buffer(1024)
        result = ctypes.c_size_t()
        ok = self.u.SendMessageTimeoutW(handle, message, len(buffer) if index is None else index,
                                       ctypes.addressof(buffer), 2, 100, ctypes.byref(result))
        return buffer.value if ok and result.value != ctypes.c_size_t(-1).value else ''

    def kind(self, handle):
        buffer = ctypes.create_unicode_buffer(256)
        self.u.GetClassNameW(handle, buffer, 256)
        return buffer.value

    def children(self, handle):
        result = []
        callback = self.callback(lambda h, _: result.append(h) or True)
        self.u.EnumChildWindows(handle, callback, 0)
        return result

    def window(self, pid):
        result = []
        def visit(handle, _):
            process = W.DWORD()
            self.u.GetWindowThreadProcessId(handle, ctypes.byref(process))
            if process.value == pid and self.text(handle).startswith('Encounter Re:Built'):
                result.append(handle)
                return False
            return True
        callback = self.callback(visit)
        self.u.EnumWindows(callback, 0)
        return result[0] if result else None

    def click(self, handle):
        return bool(handle and self.u.IsWindowEnabled(handle) and self.u.PostMessageW(handle, 0xF5, 0, 0))


class Hub:
    def __init__(self, root, update_status):
        self.root = root; self.native = Native(); self.sessions = {}; self.checked = set()
        self.data = Path(os.environ.get('LOCALAPPDATA', str(Path.home()))) / 'EncounterHub'
        self.data.mkdir(parents=True, exist_ok=True)
        self.settings_path = self.data / 'settings.json'
        try:
            self.settings = json.loads(self.settings_path.read_text('utf-8'))
        except (OSError, ValueError):
            self.settings = {}
        self.checked = set(self.settings.get('selected', []))
        self.exe = Path(self.settings.get('bot_path', str(Path(__file__).parent / 'Encounter_ReBuilt.exe')))
        self.root.title('Encounter Hub ' + VERSION); self.root.geometry('1020x560')
        self.root.minsize(850, 480); self.closing=False
        self.path_label = ttk.Label(root, text=str(self.exe)); self.path_label.pack(anchor='w', padx=12, pady=8)
        top = ttk.Frame(root); top.pack(fill='x', padx=12)
        ttk.Button(top, text='Choose Bot...', command=self.choose).pack(side='left')
        ttk.Button(top, text='Select All', command=lambda: self.select_all(True)).pack(side='left', padx=5)
        ttk.Button(top, text='Clear Selection', command=lambda: self.select_all(False)).pack(side='left')
        ttk.Label(root, text='Click the checkbox column to select characters.').pack(anchor='w', padx=12, pady=6)
        self.tree = ttk.Treeview(root, columns=('check', 'character', 'status', 'pid', 'games', 'command'), show='headings', selectmode='none')
        for key, caption, width in [('check','Select',60),('character','Character',230),('status','Bot status',230),('pid','Bot PID',70),('games','GW PIDs',110),('command','Command',300)]:
            self.tree.heading(key, text=caption); self.tree.column(key, width=width, stretch=key!='check')
        self.tree.pack(fill='both', expand=True, padx=12)
        self.tree.bind('<Button-1>', self.toggle)
        actions = ttk.Frame(root); actions.pack(fill='x', padx=12, pady=10)
        for caption, action in [('Launch Selected',self.launch),('Show Selected',self.show),('Stop Selected Bots',self.stop)]:
            ttk.Button(actions, text=caption, command=action).pack(side='left', padx=3)
        modes = ttk.Frame(root); modes.pack(fill='x', padx=12)
        for command in ('Pause','Resume','Trade Mode','Open Lockboxes'):
            ttk.Button(modes,text=command+' Selected',command=lambda c=command:self.command(c)).pack(side='left',padx=3)
        ttk.Button(modes,text='Check for Updates',command=self.check_update).pack(side='right')
        self.notice = tk.StringVar(value=update_status)
        ttk.Label(root,textvariable=self.notice,wraplength=950).pack(fill='x',padx=12,pady=10)
        self.events = queue.Queue(); self.busy_update=False
        self.root.protocol('WM_DELETE_WINDOW',self.close)
        if not self.exe.is_file(): self.choose()
        else: self.load_names()
        self.root.after(500,self.tick)
        import hub
        if not getattr(hub,'HUB_BUNDLE_SUPPORT',False): self.root.after(1000,self.check_update)

    def save(self):
        self.settings.update(bot_path=str(self.exe),selected=sorted(self.checked))
        temp=self.settings_path.with_suffix('.tmp'); temp.write_text(json.dumps(self.settings,indent=2),'utf-8'); os.replace(temp,self.settings_path)

    def choose(self):
        if any(s['process'].members() for s in self.sessions.values()):
            messagebox.showinfo('Bot folder','Stop this hub’s bot instances before changing the bot folder.'); return
        path=filedialog.askopenfilename(title='Select Encounter_ReBuilt.exe',filetypes=[('Encounter bot','Encounter_ReBuilt.exe')])
        if path: self.exe=Path(path); self.path_label.config(text=path); [s['process'].close() for s in self.sessions.values()]; self.sessions.clear(); self.load_names(); self.save()

    def load_names(self):
        ini=self.exe.parent/'Config'/'characters.ini'
        try:
            raw=ini.read_bytes()
            text=raw.decode('utf-16') if raw.startswith((b'\xff\xfe',b'\xfe\xff')) else raw.decode('utf-8-sig',errors='replace')
            names=sorted(set(re.findall(r'^\s*\[([^\]\r\n]+)\]\s*$',text,re.M)))
        except OSError as exc: messagebox.showerror('Character configuration',str(exc)); return
        self.tree.delete(*self.tree.get_children())
        for name in names: self.tree.insert('', 'end', iid=name, values=('☑' if name in self.checked else '☐',name,'Ready','','',''))

    def toggle(self,event):
        name=self.tree.identify_row(event.y)
        if name and self.tree.identify_column(event.x)=='#1':
            if name in self.checked:self.checked.remove(name)
            else:self.checked.add(name)
            self.tree.set(name,'check','☑' if name in self.checked else '☐'); self.save()

    def select_all(self,on):
        self.checked=set(self.tree.get_children()) if on else set()
        for name in self.tree.get_children():self.tree.set(name,'check','☑' if on else '☐')
        self.save()

    def selected(self):return [n for n in self.tree.get_children() if n in self.checked]

    def launch(self):
        for name in self.selected():
            if name in self.sessions and self.sessions[name]['process'].poll() is None:continue
            try:
                old=self.sessions.get(name)
                if old:
                    if old['process'].members():
                        self.tree.set(name,'command','Owned clients still open; close hub before relaunch');continue
                    old['process'].close()
                p=JobProcess(self.exe)
                self.sessions[name]=dict(process=p,phase='select',deadline=time.monotonic()+90,pending=None,command_deadline=0,sent_at=0)
                self.tree.set(name,'status','Opening bot...');self.tree.set(name,'pid',p.pid);self.tree.set(name,'command','');self.tree.set(name,'games','')
            except OSError as exc:self.tree.set(name,'status',str(exc))

    def show(self):
        for name in self.selected():
            s=self.sessions.get(name)
            if s and s['process'].poll() is None:
                h=self.native.window(s['process'].pid)
                if h:self.native.u.ShowWindow(h,9);self.native.u.SetForegroundWindow(h)

    def stop(self):
        if not messagebox.askyesno('Stop bots','Force-stop selected bots launched by this hub? Guild Wars stays open.'):return
        for name in self.selected():
            s=self.sessions.get(name)
            if s and s['process'].poll() is None:
                try:s['process'].terminate();s['pending']=None
                except OSError as exc:self.tree.set(name,'command',str(exc))

    def command(self,command):
        for name in self.selected():
            s=self.sessions.get(name)
            if not s or s['process'].poll() is not None:self.tree.set(name,'command','No running bot in this hub');continue
            if s['phase']!='done':self.tree.set(name,'command','Wait for startup to finish');continue
            s.update(pending=command,command_deadline=time.monotonic()+1800,sent_at=0)
            self.tree.set(name,'command',command+' queued')

    def step(self,name,s):
        self.tree.set(name,'games',', '.join(map(str,s['process'].games())) or '—')
        if s['process'].poll() is not None:
            self.tree.set(name,'status','Exited')
            if s['pending']:self.tree.set(name,'command','Bot exited; command cancelled');s['pending']=None
            return
        h=self.native.window(s['process'].pid)
        if not h:
            if time.monotonic()>s['deadline']:self.tree.set(name,'status','No bot window; inspect manually')
            return
        children=self.native.children(h)
        buttons={self.native.text(c):c for c in children if self.native.kind(c)=='Button'}
        if self.native.text(h)=='Encounter Re:Built - '+name:
            s['phase']='done';self.tree.set(name,'status','Started (window confirmed)')
        if s['phase']!='done':
            if time.monotonic()>s['deadline']:self.tree.set(name,'status','Needs attention; open bot');return
            if s['phase']=='select':
                for c in children:
                    if self.native.kind(c)!='ComboBox':continue
                    for i in range(1000):
                        text=self.native.text(c,0x148,i)
                        if not text:break
                        if re.sub(r'^\s*\d+\s*-\s*','',text)==name:
                            if self.native.u.PostMessageW(c,0x14E,i,0):s['phase']='start'
                            return
            elif s['phase']=='start':
                selected=any(self.native.kind(c)=='ComboBox' and re.sub(r'^\s*\d+\s*-\s*','',self.native.text(c))==name for c in children)
                if selected and self.native.click(buttons.get('Start')):
                    s.update(phase='wait',deadline=time.monotonic()+300);self.tree.set(name,'status','Start requested; waiting for game')
            return
        command=s['pending']
        if not command:return
        if time.monotonic()>s['command_deadline']:self.tree.set(name,'command','Command timed out');s['pending']=None;return
        if time.monotonic()-s['sent_at']<2:return
        target,status,done=command_action(command,buttons)
        self.tree.set(name,'command',status)
        if done:s['pending']=None;return
        if target and target in buttons:
            if self.native.click(buttons[target]):
                s['sent_at']=time.monotonic();self.tree.set(name,'command',target+' sent')
                if target!='Pause':s['pending']=None
            elif target!='Pause':self.tree.set(name,'command',target+' unavailable in bot');s['pending']=None

    def tick(self):
        if self.closing:return
        for name,s in list(self.sessions.items()):
            try:self.step(name,s)
            except Exception as exc:self.tree.set(name,'status','Needs attention: '+str(exc))
        try:
            while True:self.notice.set(self.events.get_nowait());self.busy_update=False
        except queue.Empty:pass
        self.root.after(500,self.tick)

    def check_update(self):
        if self.busy_update:return
        self.busy_update=True;self.notice.set('Checking GitHub for updates...')
        def worker():
            try:
                result=update_bundle()
                self.events.put(result+'. Close and reopen the hub to load it. Closing stops owned bots and game clients.')
            except Exception as exc:self.events.put('Update unavailable: '+str(exc))
        self.update_worker=threading.Thread(target=worker,daemon=False)
        self.update_worker.start()

    def close(self):
        if self.closing:return
        self.closing=True
        def disable(widget):
            for child in widget.winfo_children():
                if isinstance(child,ttk.Button):child.config(state='disabled')
                disable(child)
        disable(self.root)
        try:self.save()
        except OSError as exc:messagebox.showwarning('Save settings',str(exc))
        # Terminate private jobs first; never search/kill by process name or PID.
        errors=[]
        for name,s in self.sessions.items():
            s['pending']=None
            try:s['process'].shutdown()
            except OSError as exc:errors.append(name+': '+str(exc))
        # Poll until the kernel reports every owned process has exited.
        self.notice.set('Closing owned bots and Guild Wars clients...')
        deadline=time.monotonic()+10
        def finish():
            if getattr(self,'update_worker',None) and self.update_worker.is_alive():
                self.notice.set('Finishing update and closing owned clients...')
                self.root.after(100,finish);return
            alive=[]
            for name,s in self.sessions.items():
                try:
                    if s['process'].members():alive.append(name)
                except OSError as exc:errors.append(str(exc))
            if alive and time.monotonic()<deadline:
                self.root.after(100,finish);return
            if alive or errors:
                # Closing the last private job handle also enforces kill-on-close.
                messagebox.showwarning('Shutdown','Owned processes still shutting down or reported errors: '+', '.join(alive+errors))
            for s in self.sessions.values():s['process'].close()
            self.root.destroy()
        finish()


def run(update_status):
    root=tk.Tk();Hub(root,update_status);root.mainloop()
