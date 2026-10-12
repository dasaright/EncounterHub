"""Stable windowless executable entry; editable modules live beside the EXE."""
import importlib.util
import os
from pathlib import Path
import sys
# Explicit imports make the packaged runtime include required modules.
import tkinter
import socket
import ctypes
import urllib.request
import zipfile
import hashlib
import secrets
import json
import queue
import re
import threading
import time
import subprocess
import base64
import io
import shutil
import urllib.parse
import PySide6.QtCore
import PySide6.QtGui
import PySide6.QtWidgets

ROOT=Path(sys.executable).parent if getattr(sys,'frozen',False) else Path(__file__).parent
sys.path.insert(0,str(ROOT))
for name in ('hub','app_main','supervisor','qt_style','qt_app'):
    path=ROOT/(name+'.py')
    if not path.is_file():raise RuntimeError('Missing desktop module: '+str(path))
    spec=importlib.util.spec_from_file_location(name,path)
    module=importlib.util.module_from_spec(spec);sys.modules[name]=module;spec.loader.exec_module(module)

if '--smoke-test' in sys.argv:
    from qt_app import Desktop,STYLE
    from PySide6.QtWidgets import QApplication
    app=QApplication([]);app.setStyleSheet(STYLE);window=Desktop('Executable smoke test',start_supervisor=False)
    window.show();app.processEvents()
    assert window.table.columnCount()==11
    assert not window.update_button.isEnabled()
    assert window.check_button.pos().y()<window.update_button.pos().y()
    window.monitor_stop.set();window.monitor_worker.join(timeout=5)
    window.restarting=True;window.close()
    sys.exit(0)

sys.modules['hub'].main()
