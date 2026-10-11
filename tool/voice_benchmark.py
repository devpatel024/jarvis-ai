#!/usr/bin/env python3
"""Offline synthetic-clip STT evaluation; no downloads or microphone capture.

Benchmark-only audio fixtures are explicitly written to --scratch. App recording
must remain memory-only. Requires already installed eSpeak and approved engines.
"""
import argparse
import array
import ctypes
import json
import math
import os
from pathlib import Path
import re
import subprocess
import sys
import threading
import time
import urllib.request
import wave

PROMPTS = [
    ('greeting', 'Hello Jarvis. How are you today?'),
    ('question', 'What should I do first this morning?'),
    ('numbers', 'Set a timer for twenty five minutes and remind me at nine thirty.'),
]
OPENER = urllib.request.build_opener(urllib.request.ProxyHandler({}))


def ollama(path, body=None):
    data = None if body is None else json.dumps(body).encode()
    with OPENER.open(urllib.request.Request('http://127.0.0.1:11434'+path,
                                           data=data, headers={'Content-Type':'application/json'}), timeout=120) as r:
        return json.load(r)


def words(text):
    return re.findall(r"[a-z0-9]+", text.lower())


def error_rate(reference, actual):
    a, b = words(reference), words(actual)
    previous = list(range(len(b)+1))
    for i, word in enumerate(a, 1):
        current = [i]
        for j, other in enumerate(b, 1):
            current.append(min(current[-1]+1, previous[j]+1, previous[j-1]+(word!=other)))
        previous = current
    return previous[-1]/len(a)


def rss(pid):
    try:
        for line in Path(f'/proc/{pid}/status').read_text().splitlines():
            if line.startswith('VmRSS:'):
                return int(line.split()[1])*1024
    except OSError:
        pass
    return 0


def ollama_rss():
    total = 0
    for path in Path('/proc').iterdir():
        if path.name.isdigit():
            try:
                if (path/'comm').read_text().strip() in ('ollama','llama-server'):
                    total += rss(int(path.name))
            except OSError:
                pass
    return total


def worker(lib, model, clip):
    native = ctypes.CDLL(lib)
    native.vosk_set_log_level(-1)
    native.vosk_model_new.argtypes=[ctypes.c_char_p]; native.vosk_model_new.restype=ctypes.c_void_p
    native.vosk_recognizer_new.argtypes=[ctypes.c_void_p,ctypes.c_float]; native.vosk_recognizer_new.restype=ctypes.c_void_p
    native.vosk_recognizer_accept_waveform.argtypes=[ctypes.c_void_p,ctypes.c_char_p,ctypes.c_int]
    native.vosk_recognizer_final_result.argtypes=[ctypes.c_void_p]; native.vosk_recognizer_final_result.restype=ctypes.c_char_p
    native.vosk_recognizer_free.argtypes=[ctypes.c_void_p];native.vosk_model_free.argtypes=[ctypes.c_void_p]
    start=time.monotonic(); m=native.vosk_model_new(os.fsencode(model))
    if not m: raise RuntimeError('Vosk model load failed')
    recognizer=native.vosk_recognizer_new(m,16000.0)
    if not recognizer: raise RuntimeError('Vosk recognizer failed')
    loaded=time.monotonic()-start
    try:
        with wave.open(clip,'rb') as w: data=w.readframes(w.getnframes())
        native.vosk_recognizer_accept_waveform(recognizer,data,len(data))
        result=json.loads(native.vosk_recognizer_final_result(recognizer))
        print(json.dumps({'text':result['text'],'load_seconds':loaded}))
    finally:
        native.vosk_recognizer_free(recognizer);native.vosk_model_free(m)


def fixture(scratch, label, text):
    raw=scratch/(label+'-22050.wav');target=scratch/(label+'.wav')
    subprocess.run(['espeak-ng','-v','en-us','-s','150','-w',str(raw),text],check=True)
    with wave.open(str(raw),'rb') as w:
        source_rate=w.getframerate();source=array.array('h',w.readframes(w.getnframes()))
    samples=array.array('h')
    for i in range(int(len(source)*16000/source_rate)):
        p=i*source_rate/16000;lo=int(p);hi=min(lo+1,len(source)-1)
        samples.append(round(source[lo]*(1-(p-lo))+source[hi]*(p-lo)))
    with wave.open(str(target),'wb') as w:
        w.setnchannels(1);w.setsampwidth(2);w.setframerate(16000);w.writeframes(samples.tobytes())
    return target,len(samples)/16000


def main(args):
    os.environ.update(OPENBLAS_NUM_THREADS='2', OMP_NUM_THREADS='2', MKL_NUM_THREADS='2')
    scratch=Path(args.scratch);scratch.mkdir(parents=True,exist_ok=True)
    fixtures=[(label,text,*fixture(scratch,label,text)) for label,text in PROMPTS]
    if ollama('/api/ps')['models']:
        raise RuntimeError('Another model is loaded; unload explicitly first')
    report={'date':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),
            'fixture':'Synthetic eSpeak NG en-us 150 words/min; linear resample to 16 kHz. Not real speaker/microphone accuracy.',
            'conditions':'One cold STT process per clip, latency includes startup/load/transcription. llama3.2:1b CPU 2 threads/context2048 loaded but idle; no generation or builds during cases. Single run, uncontrolled desktop load.',
            'memory':'STT process VmRSS and sum of Ollama/runner VmRSS sampled every 50ms, shared pages may double-count. Not total system RAM.',
            'native_threads': {'OPENBLAS_NUM_THREADS':'2','OMP_NUM_THREADS':'2','MKL_NUM_THREADS':'2','whisper_threads':2}, 'results':[]}
    try:
        ollama('/api/generate',{'model':'llama3.2:1b','prompt':'','stream':False,'keep_alive':'15m',
                               'options':{'num_ctx':2048,'num_thread':2,'num_gpu':0}})
        report['resident']=ollama('/api/ps')
        for engine in ['whisper','vosk']:
            for label,reference,clip,duration in fixtures:
                output=scratch/(engine+'-'+label)
                command=([args.whisper,'-m',args.whisper_model,'-f',str(clip),'-t','2','-l','en','-ng','-nt','-otxt','-of',str(output)] if engine=='whisper' else
                         [sys.executable,__file__,'--worker',args.vosk_lib,args.vosk_model,str(clip)])
                peak=[0,ollama_rss()];start=time.monotonic()
                process=subprocess.Popen(command,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
                done=threading.Event()
                def monitor():
                    while not done.wait(.05):
                        peak[0]=max(peak[0],rss(process.pid));peak[1]=max(peak[1],ollama_rss())
                thread=threading.Thread(target=monitor);thread.start()
                try:
                    stdout,stderr=process.communicate(timeout=180)
                finally:
                    if process.poll() is None:process.kill();process.wait()
                    done.set();thread.join()
                elapsed=time.monotonic()-start
                if process.returncode:raise RuntimeError(stderr.decode()[-3000:])
                actual=output.with_suffix('.txt').read_text().strip() if engine=='whisper' else json.loads(stdout)['text']
                wer=error_rate(reference,actual)
                row=dict(engine=engine,clip=label,reference=reference,transcript=actual,audio_seconds=duration,
                         latency_seconds=elapsed,real_time_factor=elapsed/duration,word_error_rate=wer,
                         word_accuracy_percent=max(0,1-wer)*100,peak_stt_rss_bytes=peak[0],peak_ollama_rss_bytes=peak[1])
                report['results'].append(row);print(json.dumps(row),flush=True)
                Path(args.output).write_text(json.dumps(report,indent=2)+'\n')
    finally:
        ollama('/api/generate',{'model':'llama3.2:1b','keep_alive':0,'stream':False})
        report['resident_after']=ollama('/api/ps')
        Path(args.output).write_text(json.dumps(report,indent=2)+'\n')


if __name__=='__main__':
    if len(sys.argv)>1 and sys.argv[1]=='--worker':
        worker(*sys.argv[2:])
    else:
        p=argparse.ArgumentParser();p.add_argument('--scratch',required=True)
        for flag in ['whisper','whisper-model','vosk-lib','vosk-model','output']:p.add_argument('--'+flag,required=True)
        main(p.parse_args())
