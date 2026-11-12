import ast
import hashlib
import json
from pathlib import Path
root=Path(__file__).resolve().parents[1]
source=(root/'app_main.py').read_bytes()
module=ast.parse(source)
version=next(ast.literal_eval(n.value) for n in module.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='VERSION' for t in n.targets))
def digest(path):return hashlib.sha256((root/path).read_bytes()).hexdigest()
(root/'update.json').write_text(json.dumps({'format':1,'version':version,'files':{'app_main.py':digest('app_main.py')}},indent=2)+'\n')
legacy=['app_main.py','hub.py','Launch Hub.vbs','Launch Hub.cmd','update.json']
(root/'bundle.json').write_text(json.dumps({'format':1,'version':version,'files':{p:digest(p) for p in legacy}},indent=2)+'\n')
paths=legacy+['qt_app.py','qt_style.py','supervisor.py','supply_manager.py','requirements.txt','bundle.json']
bot_sources={
 'bot/Encounter ReBuilt/Encounter_ReBuilt.au3':'Encounter ReBuilt - PUBLIC/Encounter_ReBuilt.au3',
 'bot/Encounter ReBuilt/Encounter_ReBuilt.exe':'Encounter ReBuilt - PUBLIC/Encounter_ReBuilt.exe',
}
for name in ('AddOns.au3','GUI.au3','ItemFilter.au3','Launch.au3','Pathing.au3','Security.au3','SupplyManager.au3','_Includes.au3'):
 bot_sources['bot/Encounter ReBuilt/Files/'+name]='Encounter ReBuilt - PUBLIC/Files/'+name
for name in ('BannerGeneral.jpg','BannerLootConfig.jpg','BannerTradeConfig.jpg','Encounter.ico'):
 bot_sources['bot/Encounter ReBuilt/Images/'+name]='Encounter ReBuilt - PUBLIC/Images/'+name
files={p:digest(p) for p in paths}
files.update({destination:digest(source) for destination,source in bot_sources.items()})
(root/'desktop-bundle.json').write_text(json.dumps({'format':1,'version':version,'files':files},indent=2)+'\n')
