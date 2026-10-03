import json
import urllib.request
from pathlib import Path

def post(route, body):
    req = urllib.request.Request('http://127.0.0.1:8080' + route,
        data=json.dumps(body).encode(), headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(req, timeout=600) as response:
        return json.load(response)

text = ('La inferencia local permite procesar datos en el propio ordenador. '
        'La memoria de la GPU almacena pesos y cachés; el rendimiento depende del contexto.\n') * 510
tokens = post('/tokenize', {'content': text, 'add_special': True})['tokens'][:15800]
result = post('/completion', {'prompt': tokens, 'n_predict': 128,
    'temperature': 0, 'cache_prompt': False, 'ignore_eos': True})
Path('logs/context-16k.json').write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps({'timings': result.get('timings'), 'truncated': result.get('truncated')}))
