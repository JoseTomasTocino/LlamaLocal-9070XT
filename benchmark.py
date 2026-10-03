import json
import time
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent

def post(route, body):
    request = urllib.request.Request('http://127.0.0.1:8080' + route,
        data=json.dumps(body).encode(), headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(request, timeout=600) as response:
        return json.load(response)

basic = post('/v1/chat/completions', {
    'model': 'qwen3.8-27b',
    'messages': [{'role': 'user', 'content': 'Responde en español: ¿cuánto es 17 por 23?'}],
    'max_tokens': 512, 'temperature': 0,
    'chat_template_kwargs': {'enable_thinking': False}
})
(ROOT / 'logs/basic-generation.json').write_text(json.dumps(basic, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps(basic, ensure_ascii=False), flush=True)
prompt = ('La inferencia local permite procesar datos en el propio ordenador. '
          'La memoria de la GPU almacena pesos y cachés; el rendimiento depende del contexto.\n') * 60
for i in range(3):
    result = post('/completion', {'prompt': prompt + '\nExplica estas ideas con detalle:',
        'n_predict': 128, 'temperature': 0, 'cache_prompt': False, 'ignore_eos': True})
    (ROOT / f'logs/benchmark-{i+1}.json').write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps({'run': i+1, 'timings': result.get('timings')}), flush=True)
