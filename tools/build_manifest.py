import ast
import hashlib
import json
from pathlib import Path
root=Path(__file__).resolve().parents[1]
source=(root/'app_main.py').read_bytes()
module=ast.parse(source)
version=next(ast.literal_eval(n.value) for n in module.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='VERSION' for t in n.targets))
(root/'update.json').write_text(json.dumps({'format':1,'version':version,'files':{'app_main.py':hashlib.sha256(source).hexdigest()}},indent=2)+'\n')

legacy=['app_main.py','hub.py','Launch Hub.vbs','Launch Hub.cmd','update.json']
(root/'bundle.json').write_text(json.dumps({'format':1,'version':version,'files':{p:hashlib.sha256((root/p).read_bytes()).hexdigest() for p in legacy}},indent=2)+'\n')
paths=legacy+['qt_app.py','qt_style.py','supervisor.py','requirements.txt','bundle.json']
(root/'desktop-bundle.json').write_text(json.dumps({'format':1,'version':version,'files':{p:hashlib.sha256((root/p).read_bytes()).hexdigest() for p in paths}},indent=2)+'\n')
