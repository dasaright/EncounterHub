"""Authenticated local process owner. UI restarts never own/close job handles."""
import json
import os
from pathlib import Path
import secrets
import socket
import subprocess
import sys
import threading
import time

ENDPOINT = Path(os.environ.get('LOCALAPPDATA',str(Path.home())))/'EncounterHub'/'supervisor.json'


def receive(sock):
    chunks=bytearray()
    while len(chunks)<1_000_000:
        block=sock.recv(4096)
        if not block:break
        chunks.extend(block)
        if b'\n' in block:break
    return json.loads(bytes(chunks).split(b'\n')[0])


class Broker:
    def __init__(self,endpoint):self.endpoint=endpoint
    def call(self,operation,**kwargs):
        with socket.create_connection(('127.0.0.1',self.endpoint['port']),timeout=5) as sock:
            sock.sendall((json.dumps({'token':self.endpoint['token'],'operation':operation,**kwargs})+'\n').encode())
            reply=receive(sock)
        if 'error' in reply:raise OSError(reply['error'])
        return reply.get('result')


def command_line():
    if getattr(sys,'frozen',False):return [sys.executable]
    return [sys.executable,str(Path(__file__).parent/'hub.py')]


def ensure():
    try:
        broker=Broker(json.loads(ENDPOINT.read_text()));broker.call('ping');return broker
    except (OSError,ValueError,KeyError):pass
    subprocess.Popen(command_line()+['--supervisor'],creationflags=getattr(subprocess,'CREATE_NO_WINDOW',0))
    deadline=time.monotonic()+15
    while time.monotonic()<deadline:
        try:
            broker=Broker(json.loads(ENDPOINT.read_text()));broker.call('ping');return broker
        except (OSError,ValueError,KeyError):time.sleep(.1)
    raise OSError('Background supervisor did not start')


class RemoteProcess:
    def __init__(self,broker,identifier,pid):self.broker=broker;self.identifier=identifier;self.pid=pid
    def poll(self):return self.broker.call('poll',identifier=self.identifier)
    def terminate(self):return self.broker.call('stopbot',identifier=self.identifier)
    def shutdown(self):return self.broker.call('shutdown',identifier=self.identifier)
    def members(self):return self.broker.call('members',identifier=self.identifier)
    def games(self):return self.broker.call('games',identifier=self.identifier)
    def close(self):pass  # Lifetime belongs to the supervisor, not a GUI handle.


def serve(endpoint_path=ENDPOINT):
    from app_main import JobProcess
    endpoint_path.parent.mkdir(parents=True,exist_ok=True)
    jobs={}; token=secrets.token_hex(32)
    server=socket.socket();server.bind(('127.0.0.1',0));server.listen(8);server.settimeout(1)
    endpoint={'port':server.getsockname()[1],'token':token,'pid':os.getpid()}
    temp=endpoint_path.with_suffix('.tmp');temp.write_text(json.dumps(endpoint));os.replace(temp,endpoint_path)
    try:
        running=True
        while running:
            try:client,_=server.accept()
            except socket.timeout:continue
            with client:
                client.settimeout(5)
                try:
                    request=receive(client)
                    if not secrets.compare_digest(str(request.get('token','')),token):raise ValueError('Invalid supervisor authentication')
                    op=request.get('operation');result=None
                    if op=='ping':result={'protocol':1,'pid':os.getpid()}
                    elif op=='snapshot':result=[{'identifier':key,'character':value['character'],'pid':value['process'].pid,'exe':value['exe'],'active':bool(value['process'].members())} for key,value in jobs.items()]
                    elif op=='launch':
                        exe=Path(request['exe']).resolve();character=str(request['character'])
                        if any(v['character']==character and v['exe']==str(exe) and v['process'].members() for v in jobs.values()):raise ValueError('This character already has an active owned session')
                        process=JobProcess(exe,request.get('arguments',()));identifier=secrets.token_hex(16)
                        jobs[identifier]={'process':process,'character':character,'exe':str(exe)}
                        result={'identifier':identifier,'pid':process.pid}
                    elif op=='exit':
                        if any(v['process'].members() for v in jobs.values()):raise ValueError('Owned sessions still active')
                        running=False
                    elif op in ('poll','stopbot','shutdown','members','games'):
                        process=jobs[request['identifier']]['process']
                        result={'poll':process.poll,'stopbot':process.terminate,'shutdown':process.shutdown,'members':process.members,'games':process.games}[op]()
                    else:raise ValueError('Unknown supervisor operation')
                    client.sendall((json.dumps({'result':result})+'\n').encode())
                except Exception as exc:
                    try:client.sendall((json.dumps({'error':str(exc)})+'\n').encode())
                    except OSError:pass
    finally:
        for value in jobs.values():value['process'].close()
        server.close()
        try:
            if json.loads(endpoint_path.read_text()).get('token')==token:endpoint_path.unlink()
        except (OSError,ValueError):pass
