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
    # CI verifies that the frozen executable can import the packaged UI stack.
    # UI construction and behavior are covered by the Python test suite; avoid
    # starting monitor workers or native windows in the headless smoke process.
    from qt_app import Desktop,STYLE
    assert callable(Desktop)
    assert isinstance(STYLE,str) and STYLE
    os._exit(0)
sys.modules['hub'].main()
