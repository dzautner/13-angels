"""Render a params file with overrides and print every score component.
    .venv/bin/python analysis/trial.py base.json '{"synth": {"unison": 8}}' ..."""
import json, os, subprocess, sys, tempfile
sys.path.insert(0, os.path.dirname(__file__))
import optimize as o, texture, micro
base = json.load(open(sys.argv[1]))
for ov in sys.argv[2:]:
    p = json.loads(json.dumps(base))
    for g, d in json.loads(ov).items(): p.setdefault(g, {}).update(d)
    js, wav = os.path.join(o.TMP, 't.json'), os.path.join(o.TMP, 't.wav')
    json.dump(p, open(js, 'w'))
    subprocess.run([o.SCLANG, 'sc/render.scd', wav, js, '2'], cwd=o.ROOT, capture_output=True)
    print(ov); o.score(wav, verbose=True)
    x = texture.measure(wav)
    print('   hnr', [round(v, 1) for v in x['hnr']], 'am', [round(v, 1) for v in x['am']], 'linewidth', round(micro.linewidth(wav), 2))
print("orig: hnr", [round(v, 1) for v in o.ORIG_TEX['hnr']], "am", [round(v, 1) for v in o.ORIG_TEX['am']], "linewidth 3.20")
