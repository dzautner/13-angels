"""Write tuned parameters (analysis/best.json) into the SuperCollider defaults:
~angelDefaults in sc/angel.scd, the \\angelRoom arg defaults, ~introDefaults in
sc/intro.scd.

    .venv/bin/python analysis/bake.py [best.json]
"""
import json, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
best = json.load(open(sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, 'analysis/best.json')))

def fmt(v):
    if isinstance(v, list):
        return '[' + ', '.join(fmt(x) for x in v) + ']'
    return f'{v:.4g}'

def set_key(text, key, value, scope_start):
    """replace `key: <value>` inside the Event literal that starts at scope_start"""
    end = text.index(');', scope_start)
    block = text[scope_start:end]
    pat = re.compile(r'(\b' + key + r':\s*)(\[[^\]]*\]|[-\d.e]+)')
    if not pat.search(block):
        raise KeyError(key)
    block = pat.sub(lambda m: m.group(1) + fmt(value), block, count=1)
    return text[:scope_start] + block + text[end:]

p = os.path.join(ROOT, 'sc/angel.scd'); s = open(p).read()
for k, v in best['synth'].items():
    s = set_key(s, k, v, s.index('~angelDefaults = ('))
room = s.index('SynthDef(\\angelRoom')
for k, v in best.get('room', {}).items():
    s = s[:room] + re.sub(r'(\b' + k + r'\s*=\s*)[-\d.e]+', lambda m: m.group(1) + fmt(v), s[room:], count=1)
open(p, 'w').write(s)

p = os.path.join(ROOT, 'sc/intro.scd'); s = open(p).read()
for k, v in best['score'].items():
    s = set_key(s, k, v, s.index('~introDefaults = ('))
open(p, 'w').write(s)
print('baked', sum(len(v) for v in best.values()), 'parameters')
