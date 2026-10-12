"""Stable launcher/updater. Python 3.10+, Windows, standard library only."""
import base64
import ctypes
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import urllib.request

HUB_BUNDLE_SUPPORT = True
REPOSITORY = 'dasaright/EncounterHub'
ROOT = Path(sys.executable).resolve().parent if getattr(sys,'frozen',False) else Path(__file__).resolve().parent


def api(path):
    req = urllib.request.Request('https://api.github.com/repos/' + REPOSITORY + '/' + path,
                                 headers={'User-Agent': 'EncounterHub', 'Accept': 'application/vnd.github+json'})
    with urllib.request.urlopen(req, timeout=8) as response:
        return json.loads(response.read(2_000_000))


def remote_file(path, commit):
    data = api('contents/' + path + '?ref=' + commit)
    if data.get('encoding') != 'base64':
        raise ValueError('Unexpected GitHub file encoding')
    return base64.b64decode(data['content'])


def validate_manifest(manifest):
    if manifest.get('format') != 1 or manifest.get('files', {}).keys() != {'app_main.py'}:
        raise ValueError('Unsupported update manifest')
    if not isinstance(manifest.get('version'), str) or not manifest['version']:
        raise ValueError('Missing update version')
    digest = manifest['files']['app_main.py']
    if not isinstance(digest, str) or len(digest) != 64 or any(c not in '0123456789abcdef' for c in digest):
        raise ValueError('Invalid update hash')


def update(root=ROOT):
    # Pin both manifest and code to the same immutable commit.
    commit = api('git/ref/heads/main')['object']['sha']
    manifest_bytes = remote_file('update.json', commit)
    manifest = json.loads(manifest_bytes)
    validate_manifest(manifest)
    target = root / 'app_main.py'
    if target.exists() and hashlib.sha256(target.read_bytes()).hexdigest() == manifest['files']['app_main.py']:
        return 'Already up to date (' + manifest['version'] + ')'
    payload = remote_file('app_main.py', commit)
    if hashlib.sha256(payload).hexdigest() != manifest['files']['app_main.py']:
        raise ValueError('Update hash does not match; keeping installed version')
    compile(payload, 'app_main.py', 'exec')
    temporary = root / 'app_main.py.download'
    temporary.write_bytes(payload)
    if target.exists():
        (root / 'app_main.py.backup').write_bytes(target.read_bytes())
    os.replace(temporary, target)
    return 'Updated to ' + manifest['version']


def elevate():
    if not ctypes.windll.shell32.IsUserAnAdmin():
        args = subprocess.list2cmdline(([] if getattr(sys,'frozen',False) else [str(ROOT/'hub.py')])+sys.argv[1:])
        result = ctypes.windll.shell32.ShellExecuteW(None, 'runas', sys.executable, args, str(ROOT), 1)
        if result <= 32:
            raise RuntimeError('Administrator launch was cancelled or failed')
        return True
    return False


def wait_for_exit(pid):
    kernel=ctypes.WinDLL('kernel32',use_last_error=True)
    kernel.OpenProcess.argtypes=[ctypes.c_uint32,ctypes.c_bool,ctypes.c_uint32];kernel.OpenProcess.restype=ctypes.c_void_p
    kernel.WaitForSingleObject.argtypes=[ctypes.c_void_p,ctypes.c_uint32];kernel.CloseHandle.argtypes=[ctypes.c_void_p]
    handle=kernel.OpenProcess(0x100000,False,pid)
    if handle:
        result=kernel.WaitForSingleObject(handle,30000);kernel.CloseHandle(handle)
        if result==0x102:raise RuntimeError('Previous hub has not finished restarting')


def install_desktop():
    import shutil
    import zipfile
    import io
    release=api('releases/latest')
    assets={a['name']:a for a in release['assets']}
    url=assets['EncounterHub-Windows.zip']['browser_download_url']
    hash_url=assets['EncounterHub-Windows.zip.sha256']['browser_download_url']
    def download(address):
        req=urllib.request.Request(address,headers={'User-Agent':'EncounterHub'})
        with urllib.request.urlopen(req,timeout=120) as response:return response.read()
    payload=download(url);digest=download(hash_url).decode().split()[0]
    if hashlib.sha256(payload).hexdigest()!=digest:raise RuntimeError('Executable download hash mismatch')
    target=Path(os.environ['LOCALAPPDATA'])/'EncounterHub'/'Desktop'
    target.mkdir(parents=True,exist_ok=True)
    with zipfile.ZipFile(io.BytesIO(payload)) as archive:
        for item in archive.infolist():
            dest=(target/item.filename).resolve()
            if not dest.is_relative_to(target.resolve()):raise RuntimeError('Unsafe executable archive path')
        archive.extractall(target)
    executable=target/'EncounterHub'/'EncounterHub.exe'
    subprocess.Popen([str(executable),'--wait-pid',str(os.getpid())],cwd=str(executable.parent))


def main():
    if os.name != 'nt':
        raise SystemExit('Encounter Hub requires Windows.')
    if elevate():
        return
    if '--supervisor' in sys.argv:
        from supervisor import serve
        serve();return
    if '--wait-pid' in sys.argv:
        wait_for_exit(int(sys.argv[sys.argv.index('--wait-pid')+1]))
    # One hub at a time prevents duplicate control/update sessions.
    kernel = ctypes.WinDLL('kernel32', use_last_error=True)
    kernel.CreateMutexW.argtypes = [ctypes.c_void_p, ctypes.c_bool, ctypes.c_wchar_p]
    kernel.CreateMutexW.restype = ctypes.c_void_p
    mutex = kernel.CreateMutexW(None, False, 'Local\\EncounterHubPython')
    if not mutex or ctypes.get_last_error() == 183:
        ctypes.windll.user32.MessageBoxW(None, 'Encounter Hub is already open.', 'Encounter Hub', 0)
        return
    try:
        if str(ROOT) not in sys.path:sys.path.insert(0,str(ROOT))
        if not (ROOT/'app_main.py').exists():
            update()
        import app_main
        # New installs use explicit Check/Update Now, never install silently.
        if app_main.VERSION.startswith('1.'):
            update()
            import importlib
            importlib.reload(app_main)
        if not (ROOT/'qt_app.py').exists() or not (ROOT/'supervisor.py').exists():
            app_main.update_bundle()
        status='Ready - use Check for Updates to find a newer version'
        app_main.run(status)
    except Exception as exc:
        ctypes.windll.user32.MessageBoxW(None, str(exc), 'Encounter Hub error', 16)
    finally:
        kernel.CloseHandle.argtypes = [ctypes.c_void_p]
        kernel.CloseHandle(mutex)


if __name__ == '__main__':
    main()
