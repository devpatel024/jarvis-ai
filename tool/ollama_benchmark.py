#!/usr/bin/env python3
"""Reference-machine, local-only, existing-model comparison. Never pulls models."""
import argparse
import json
import os
from pathlib import Path
import platform
import threading
import time
import urllib.request

ENDPOINT = 'http://127.0.0.1:11434'
OPENER = urllib.request.build_opener(urllib.request.ProxyHandler({}))
MODELS = ['llama3.2:1b', 'llama3.2:3b']
PROMPTS = [
    ('English', 'Say hello and ask how my day is going. Reply in one short sentence.'),
    ('English', 'List two steps to plan a day. Keep it brief.'),
    ('Gujarati', 'નમસ્તે! મારા દિવસ વિશે એક સરળ પ્રશ્ન પૂછો.'),
    ('Gujarati', 'મારા દિવસનું આયોજન કરવા બે સરળ પગલાં જણાવો.'),
]
def system_prompt(language):
    instruction = ('Reply in Gujarati using Gujarati script, never Hindi or Devanagari unless the user explicitly requests it.'
                   if language == 'Gujarati' else 'Reply in English.')
    return ('You are JARVIS, a helpful local assistant. Be concise and honest when unsure. '
            + instruction + ' Do not pretend to execute tools or access live information.')

def request(path, body=None):
    data = json.dumps(body, ensure_ascii=False).encode() if body is not None else None
    return OPENER.open(urllib.request.Request(ENDPOINT + path, data=data,
                      headers={'Content-Type': 'application/json'}), timeout=120)

def get_json(path, body=None):
    with request(path, body) as response:
        return json.load(response)

def rss():
    total = 0
    for path in Path('/proc').iterdir():
        if not path.name.isdigit():
            continue
        try:
            lines = (path / 'status').read_text().splitlines()
            name = next(line.split()[1] for line in lines if line.startswith('Name:'))
            if name in ['ollama', 'llama-server']:
                total += next(int(line.split()[1]) * 1024 for line in lines if line.startswith('VmRSS:'))
        except (OSError, StopIteration):
            pass
    return total

def memory():
    data = {}
    for line in Path('/proc/meminfo').read_text().splitlines():
        key, value = line.split(':', 1)
        if key in ['MemTotal', 'MemAvailable', 'SwapTotal', 'SwapFree']:
            data[key] = int(value.split()[0]) * 1024
    return data

def run(refresh_english=False, models=None, gujarati_only=False, output_path=None):
    models = models or MODELS
    allowed = MODELS + ['qwen2.5:1.5b', 'qwen3:0.6b']
    if any(m not in allowed for m in models):
        raise ValueError('Only explicitly approved models may be tested')
    installed = get_json('/api/tags')['models']
    if any(model not in [row['name'] for row in installed] for model in models):
        raise RuntimeError('Required models missing. No downloads performed.')
    loaded = get_json('/api/ps')['models']
    if any(row['name'] not in models for row in loaded):
        raise RuntimeError('Another model is resident. Stop it explicitly before benchmarking.')
    for row in loaded:
        get_json('/api/generate', {'model': row['name'], 'keep_alive': 0, 'stream': False})
    report = {'utc':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),
              'ollama':get_json('/api/version')['version'], 'platform':platform.platform(),
              'cpu':next(line.split(':',1)[1].strip() for line in Path('/proc/cpuinfo').read_text().splitlines() if line.startswith('model name')),
              'memory_before':memory(), 'installed':installed, 'options':{'num_ctx':2048,'num_predict':256,'num_gpu':0,'num_thread':2,'temperature':0,'seed':42},
              'rss_method':'Peak sum of VmRSS for visible ollama and llama-server processes sampled every 100 ms; shared pages may be counted twice. Server + runner, not app RSS.',
              'system_prompts':{lang:system_prompt(lang) for lang in ['English','Gujarati']},
              'conditions':'First prompt/model cold; later prompts warm. No model pulls. Fixed prompts, one run each; not statistically robust. Alternatives may be Gujarati-only; see recorded prompts.', 'results':[]}
    output = Path(output_path or 'docs/performance/ollama-comparison.json')
    output.parent.mkdir(parents=True,exist_ok=True)
    if refresh_english:
        previous = json.loads(output.read_text())
        gujarati = [r for r in previous['results'] if r['language'] == 'Gujarati']
        if len(gujarati) != 4 or previous['system_prompts']['Gujarati'] != system_prompt('Gujarati') or previous['options'] != report['options']:
            raise RuntimeError('Refresh requires four matching completed Gujarati samples. Run the complete comparison first.')
        report['results'] = gujarati
        report['gujarati_source_run_utc'] = previous['utc']
        report['gujarati_source_memory_before'] = previous['memory_before']
        report['conditions'] += ' English cases refreshed after simplifying English-only instructions; Gujarati cases retained from the prior identical Gujarati prompt/options run. Each model cold on its first English sample; Gujarati samples were warm in the prior full run.'
    for model in models:
        try:
            selected = [p for p in PROMPTS if (not refresh_english or p[0] == 'English') and (not gujarati_only or p[0] == 'Gujarati')]
            if get_json('/api/ps')['models']:
                raise RuntimeError('A model is still loaded before starting the next model')
            for index, (language,prompt) in enumerate(selected):
                stop = threading.Event()
                peak = [rss()]
                def sample():
                    while not stop.wait(.1):
                        peak[0] = max(peak[0],rss())
                monitor = threading.Thread(target=sample,daemon=True)
                monitor.start(); start=time.monotonic(); first=None; text=''; final=None; thinking_characters=0
                try:
                    with request('/api/chat',{'model':model,'messages':[{'role':'system','content':system_prompt(language)},{'role':'user','content':prompt}], 'stream':True,'think':False,'keep_alive':'30s','options':report['options']}) as response:
                        for line in response:
                            item=json.loads(line)
                            if 'error' in item:
                                raise RuntimeError('Ollama generation failed')
                            thinking_characters += len(item.get('message',{}).get('thinking',''))
                            delta=item.get('message',{}).get('content','')
                            if delta and first is None:
                                first=time.monotonic()-start
                            text+=delta
                            if item.get('done'):
                                final=item
                    if final is None:
                        raise RuntimeError('Stream did not complete')
                finally:
                    stop.set();monitor.join();peak[0]=max(peak[0],rss())
                row={'model':model,'language':language,'prompt':prompt,'reply':text,'cold':index==0,
                     'measured_utc':time.strftime('%Y-%m-%dT%H:%M:%SZ',time.gmtime()),
                     'system_prompt':system_prompt(language),
                     'ttft_seconds':first,'round_trip_seconds':time.monotonic()-start,
                     'thinking_disabled':True,'thinking_characters':thinking_characters,'done_reason':final.get('done_reason'),
                     'eval_count':final['eval_count'],'eval_duration_ns':final['eval_duration'],
                     'tokens_per_second':final['eval_count']/(final['eval_duration']/1e9),
                     'peak_ollama_rss_bytes':peak[0],
                     'gujarati_characters':sum('\u0a80'<=c<='\u0aff' for c in text),
                     'devanagari_characters':sum('\u0900'<=c<='\u097f' for c in text),
                     'resident':get_json('/api/ps')['models']}
                if thinking_characters:
                    raise RuntimeError('Thinking output received despite think:false')
                if len(row['resident']) != 1 or row['resident'][0]['name'] != model or row['resident'][0].get('size_vram',0) != 0:
                    raise RuntimeError('Expected exactly one CPU-only resident model')
                report['results'].append(row);output.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
                print(json.dumps({k:v for k,v in row.items() if k not in ['reply','prompt','resident']},ensure_ascii=False),flush=True)
        finally:
            get_json('/api/generate',{'model':model,'keep_alive':0,'stream':False})
    report['resident_after']=get_json('/api/ps')['models'];report['memory_after']=memory();output.write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')

if __name__=='__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--refresh-english', action='store_true', help='Retain matching Gujarati measurements and refresh only the English cases after a language-prompt revision.')
    parser.add_argument('--models', nargs='+', choices=MODELS + ['qwen2.5:1.5b','qwen3:0.6b'])
    parser.add_argument('--gujarati-only', action='store_true')
    parser.add_argument('--output')
    args = parser.parse_args()
    run(args.refresh_english, args.models, args.gujarati_only, args.output)
