"""Exercise the compiled supervisor, not the source process owner."""
import json
from pathlib import Path
import subprocess
import sys
import time
sys.path.insert(0,str(Path(__file__).resolve().parents[1]))
from supervisor import ENDPOINT,Broker

broker=None
unrelated=subprocess.Popen([sys.executable,'-c','import time;time.sleep(90)'])
try:
    deadline=time.monotonic()+30
    while time.monotonic()<deadline:
        try:
            broker=Broker(json.loads(ENDPOINT.read_text()));broker.call('ping');break
        except (OSError,ValueError):time.sleep(.1)
    assert broker is not None,'Compiled supervisor failed to start'
    record=broker.call('launch',exe=sys.executable,character='Packaged Test',arguments=['-c','import subprocess,sys,time;subprocess.Popen([sys.executable,"-c","import time;time.sleep(90)"]);time.sleep(90)'])
    identifier=record['identifier']
    deadline=time.monotonic()+10
    while len(broker.call('members',identifier=identifier))<2 and time.monotonic()<deadline:time.sleep(.1)
    assert len(broker.call('members',identifier=identifier))>=2
    del broker
    broker=Broker(json.loads(ENDPOINT.read_text()))
    assert broker.call('poll',identifier=identifier) is None
    broker.call('stopbot',identifier=identifier)
    deadline=time.monotonic()+10
    while broker.call('poll',identifier=identifier) is None and time.monotonic()<deadline:time.sleep(.1)
    assert broker.call('poll',identifier=identifier) is not None
    broker.call('shutdown',identifier=identifier)
    deadline=time.monotonic()+10
    while broker.call('members',identifier=identifier) and time.monotonic()<deadline:time.sleep(.1)
    assert broker.call('members',identifier=identifier)==[]
    assert unrelated.poll() is None
    print('Compiled supervisor launch, reconnection and selective shutdown verified')
finally:
    if broker:
        try:
            for record in broker.call('snapshot'):broker.call('shutdown',identifier=record['identifier'])
            broker.call('exit')
        except OSError:pass
    unrelated.terminate();unrelated.wait(timeout=10)
