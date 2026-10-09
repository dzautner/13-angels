"""Tune the angel voice against the record.

Renders sc/render.scd offline with candidate parameters (CMA-ES, in parallel),
scores each render by the RMS difference of the event-averaged mel spectrogram
against the original intro, and keeps the best in analysis/best.json.

    .venv/bin/python analysis/optimize.py [generations] [start.json]
"""
import json, os, subprocess, sys, tempfile, time
from concurrent.futures import ThreadPoolExecutor
import numpy as np, cma

sys.path.insert(0, os.path.dirname(__file__))
from avgevent import avg_event, err
import falls, micro, texture, decay, formants

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SCLANG = '/Applications/SuperCollider.app/Contents/MacOS/sclang'
TMP = tempfile.mkdtemp(prefix='angel-opt-')

# (group, name, index-or-None, lo, hi)
SPACE = [
    ('synth', 'openF', 0, 650, 1050), ('synth', 'openF', 1, 1000, 1600), ('synth', 'openF', 2, 2200, 3200),
    ('synth', 'openB', 0, 80, 400), ('synth', 'openB', 1, 80, 400), ('synth', 'openB', 2, 120, 500),
    ('synth', 'openA', 1, 0.05, 1.2), ('synth', 'openA', 2, 0.0, 0.3),
    ('synth', 'closedF', 0, 250, 450), ('synth', 'closedF', 1, 600, 1050), ('synth', 'closedF', 2, 2000, 3000),
    ('synth', 'closedB', 0, 60, 350), ('synth', 'closedB', 1, 80, 400),
    ('synth', 'closedA', 1, 0.02, 1.0), ('synth', 'closedA', 2, 0.0, 0.2),
    ('synth', 'closeStart', None, 0.3, 1.2),
    ('synth', 'tilt', None, 0.0, 1.5), ('synth', 'hiCut', None, 1500, 8000),
    ('synth', 'closeTime', None, 0.8, 2.5), ('synth', 'closeMid', None, 0.0, 0.6),
    ('synth', 'voiceDelay', None, 0.0, 0.2), ('synth', 'attack', None, 0.03, 0.4),
    ('synth', 'swell', None, 0.3, 1.8), ('synth', 'swellDepth', None, 0.0, 0.8),
    ('synth', 'fallLevel', None, 0.15, 0.9), ('synth', 'fallCurve', None, -3, 4),
    ('synth', 'cutTime', None, 0.1, 0.6), ('synth', 'cutCurve', None, -4, 4),
    ('synth', 'fallDark', None, 0.0, 2.5), ('synth', 'fallWobble', None, 0.0, 0.4), ('synth', 'fallShape', None, -4, 2),
    ('synth', 'breath', None, 0.0, 2.0), ('synth', 'bed', None, 0.0, 1.0),
    ('synth', 'hLevel', None, 0.0, 0.6), ('synth', 'exhale', None, 0.0, 10.0),
    ('synth', 'noiseHi', None, 800, 3000),
    ('synth', 'scoop', None, 0.0, 0.8), ('synth', 'drift', None, 0.0, 0.6),
    ('synth', 'wander', None, 0.0, 0.25), ('synth', 'wanderRate', None, 0.2, 3.0),
    ('synth', 'vib', None, 0.0, 0.08), ('synth', 'jitter', None, 0.0, 0.01),
    ('synth', 'shimmer', None, 0.0, 1.5), ('synth', 'shimmerTilt', None, 0.2, 2.0),
    ('synth', 'unison', None, 0.0, 15.0), ('synth', 'uniMix', None, 0.0, 0.5),
    ('synth', 'midBreath', None, 0.0, 0.3), ('synth', 'midFreq', None, 400, 1600), ('synth', 'midQ', None, 0.3, 2.0),
    ('room', 'mix', None, 0.0, 0.6), ('room', 'room', None, 0.1, 0.95), ('room', 'damp', None, 0.0, 1.0),
    ('room', 'gateThresh', None, 0.002, 0.1), ('room', 'gateRel', None, 0.02, 0.6), ('room', 'gateFloor', None, 0.0, 0.5),
    ('synth', 'rumble', None, 0.0, 1.0), ('synth', 'rumbleFreq', None, 80, 300),
    ('score', 'lead', None, 0.0, 0.3), ('score', 'relPedal', None, 1.3, 2.0),
    ('score', 'relSlope', None, 0.0, 0.12), ('score', 'depth', None, 2.0, 9.0),
    ('score', 'landAt', None, 1.6, 2.3), ('score', 'depthPedal', None, 1.8, 4.0), ('score', 'upperAmp', None, 0.4, 1.2),
]
FIXED = {'synth': {'openA': [1.0, None, None], 'closedA': [1.0, None, None],
                   'closedB': [None, None, 600]}, 'room': {}, 'score': {}}
START = {  # current hand-tuned values
    ('openF', 0): 680, ('openF', 1): 1180, ('openF', 2): 2700, ('openB', 0): 300, ('openB', 1): 350,
    ('openB', 2): 600, ('openA', 1): 0.626, ('openA', 2): 0.219, ('closedF', 0): 330, ('closedF', 1): 760,
    ('closedF', 2): 2500, ('closedB', 0): 220, ('closedB', 1): 280, ('closedA', 1): 0.347,
    ('closedA', 2): 0.122, 'tilt': 0.5, 'hiCut': 7000, 'closeTime': 1.45, 'closeMid': 0.25,
    'voiceDelay': 0.09, 'attack': 0.1, 'swell': 1.1, 'swellDepth': 0.4, 'relScale': 1.05,
    'relCurve': 1.5, 'breath': 0.5, 'bed': 0.35, 'hLevel': 0.16, 'exhale': 2.2, 'noiseHi': 1700,
    'scoop': 0.35, 'drift': 0.2, 'wander': 0.05, 'wanderRate': 0.7, 'vib': 0.025, 'jitter': 0.004, 'shimmer': 0.5, 'shimmerTilt': 0.5, 'midBreath': 0.0, 'midFreq': 750, 'midQ': 1.0, 'unison': 0.0, 'uniMix': 0.0,
    'mix': 0.14, 'room': 0.4, 'damp': 0.65, 'rumble': 0.0, 'rumbleFreq': 180,
    'lead': 0.09, 'relPedal': 1.65, 'relSlope': 0.075, 'depth': 3.0, 'fallBase': 0.45, 'fallPerSemi': 0.08, 'upperAmp': 0.8,
}

def decode(u):
    p = json.loads(json.dumps(FIXED))
    for (g, name, idx, lo, hi), v in zip(SPACE, np.clip(u, 0, 1)):
        val = lo + v * (hi - lo)
        if idx is None:
            p[g][name] = val
        else:
            arr = p[g].setdefault(name, [None, None, None]); arr[idx] = val
    return p

def encode(params):
    u = []
    for g, name, idx, lo, hi in SPACE:
        v = params[g][name] if idx is None else params[g][name][idx]
        u.append((v - lo) / (hi - lo))
    return np.clip(np.array(u), 0, 1)

def start_params():
    p = json.loads(json.dumps(FIXED))
    for g, name, idx, lo, hi in SPACE:
        v = START[name] if idx is None else START[(name, idx)]
        if idx is None: p[g][name] = v
        else: p[g].setdefault(name, [None, None, None])[idx] = v
    return p

ORIG = avg_event(os.path.join(ROOT, 'ref/orig.wav'))
ORIG_FALLS = falls.run(os.path.join(ROOT, 'ref/orig.wav'), quiet=True)
ORIG_MICRO = micro.stats(os.path.join(ROOT, 'ref/orig.wav'))
ORIG_TEX = texture.measure(os.path.join(ROOT, 'ref/orig.wav'))
ORIG_DECAY = decay.curves(os.path.join(ROOT, 'ref/orig.wav'))
_, ORIG_LPC, LPC_W = formants.trajectory(os.path.join(ROOT, 'ref/orig.wav'))
LPC_M = (LPC_W > 150) & (LPC_W < 4000)

def lpc_err(env):
    """vowel distance: frame-normalised LPC envelopes, clipped at -25 dB, RMS dB"""
    n = lambda E: np.maximum(E[:, LPC_M] - E[:, LPC_M].max(1, keepdims=True), -25)
    return np.sqrt(np.mean((n(env) - n(ORIG_LPC)) ** 2))

def score(wav, verbose=False):
    """mel error (dB) + penalties for fall timing and micro-motion mismatch"""
    mel = err(ORIG, avg_event(wav))
    fs = falls.run(wav, quiet=True)
    t_pen = sum(((fs[r][0] - ORIG_FALLS[r][0]) / 0.1) ** 2 for r in ('pedal', 'top')) * 0.3
    ms = micro.stats(wav)
    # slow pitch wander (cents) and H2 shimmer (dB), compared in log ratio
    m_pen = sum(np.log(ms[h][i] / ORIG_MICRO[h][i]) ** 2 for h in (1, 2) for i in (1, 3)) * 0.5
    tx = texture.measure(wav)
    # harmonic-to-noise per band (dB) and AM texture per band (%, log ratio)
    h_pen = sum(((tx['hnr'][i] - ORIG_TEX['hnr'][i]) / 3) ** 2 for i in range(4)) * 0.25
    a_pen = sum(np.log(tx['am'][i] / ORIG_TEX['am'][i]) ** 2 for i in range(4)) * 1.0
    # the sigh, every 50 ms: pedal pitch (st), pedal level (dB), brightness (dB)
    _, pp, pl, pb = decay.curves(wav); _, op, ol, ob = ORIG_DECAY
    d_pen = (np.sqrt(np.mean((pp - op) ** 2)) / 0.3) ** 2 * 0.3 \
        + (np.sqrt(np.mean((np.maximum(pl, -45) - np.maximum(ol, -45)) ** 2)) / 3) ** 2 * 0.3 \
        + (np.sqrt(np.mean((pb - ob) ** 2)) / 3) ** 2 * 0.3
    # the vowel ("Ah" -> "u"), frame by frame, pitch-independent
    lp = lpc_err(formants.trajectory(wav)[1])
    v_pen = (lp / 2.0) ** 2 * 0.5
    if verbose:
        print(f"mel {mel:.2f}  timing {t_pen:.2f}  micro {m_pen:.2f}  hnr {h_pen:.2f}  am {a_pen:.2f}  decay {d_pen:.2f}  vowel {v_pen:.2f} (lpc rms {lp:.1f} dB)")
    return mel + t_pen + m_pen + h_pen + a_pen + d_pen + v_pen

def evaluate(params, tag):
    js, wav = os.path.join(TMP, f'{tag}.json'), os.path.join(TMP, f'{tag}.wav')
    with open(js, 'w') as f: json.dump(params, f)
    r = subprocess.run([SCLANG, 'sc/render.scd', wav, js, '2'], cwd=ROOT, capture_output=True, text=True, timeout=120)
    if not os.path.exists(wav):
        print('render failed', tag, r.stdout[-500:]); return 99.0
    try:
        return score(wav)
    finally:
        os.remove(wav); os.remove(js)

if __name__ == '__main__':
    gens = int(sys.argv[1]) if len(sys.argv) > 1 else 40
    p0 = json.load(open(sys.argv[2])) if len(sys.argv) > 2 else start_params()
    x0 = encode(p0)
    best = (evaluate(p0, 'start'), p0); print(f'start: {best[0]:.3f} dB', flush=True)
    es = cma.CMAEvolutionStrategy(x0, 0.15, {'bounds': [0, 1], 'popsize': 16, 'seed': 1, 'verbose': -9})
    pool = ThreadPoolExecutor(max_workers=11)
    for g in range(gens):
        t = time.time()
        xs = es.ask()
        ps = [decode(x) for x in xs]
        losses = list(pool.map(lambda a: evaluate(a[1], f'g{g}_{a[0]}'), enumerate(ps)))
        es.tell(xs, losses)
        i = int(np.argmin(losses))
        if losses[i] < best[0]:
            best = (losses[i], ps[i])
            json.dump(best[1], open(os.path.join(ROOT, 'analysis/best.json'), 'w'), indent=1)
        print(f'gen {g:3d}: gen-best {losses[i]:.3f}  overall {best[0]:.3f}  median {np.median(losses):.3f}  ({time.time() - t:.0f}s)', flush=True)
    print('done; best', best[0])
