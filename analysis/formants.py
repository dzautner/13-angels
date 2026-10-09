"""Formant trajectory through a chord event (LPC on the mix, averaged over
events). With three voices the harmonics sample the vocal-tract envelope
densely, so the LPC envelope peaks are a fair estimate of F1/F2/F3."""
import sys, numpy as np, librosa, scipy.signal as ss
SR = 11025; P, S = 2.5704, 0.38

def envelope_peaks(seg, order=14):
    seg = ss.lfilter([1, -0.7], 1, seg) * np.hamming(len(seg))     # gentle pre-emphasis
    a = librosa.lpc(seg, order=order)
    w, h = ss.freqz(1, a, worN=2048, fs=SR)
    db = 20 * np.log10(np.abs(h) + 1e-9)
    pk, prop = ss.find_peaks(db, prominence=2)
    f = w[pk]; keep = (f > 200) & (f < 4000)
    return f[keep], db, w

def trajectory(path, n0=2, n1=16):
    y, _ = librosa.load(path, sr=SR, duration=S + n1 * P + 3)
    ts = np.arange(0.1, 2.1, 0.1); env = []
    for t in ts:
        acc = None
        for n in range(n0, n1):
            o = S + n * P; seg = y[int((o + t) * SR):int((o + t + 0.08) * SR)]
            _, db, w = envelope_peaks(seg)
            acc = db if acc is None else acc + db
        env.append(acc / (n1 - n0))
    out = []
    for t, db in zip(ts, env):
        pk, _ = ss.find_peaks(db, prominence=1.5)
        f = w[pk]; f = f[(f > 200) & (f < 4000)]
        out.append((t, f[:4]))
    return out, np.array(env), w

if __name__ == '__main__':
    o, oe, w = trajectory('ref/orig.wav')
    s, se, _ = trajectory(sys.argv[1]) if len(sys.argv) > 1 else (None, None, None)
    for i, (t, f) in enumerate(o):
        line = f"{t:4.1f}s  orig: " + " ".join(f"{x:5.0f}" for x in f).ljust(26)
        if s: line += "| synth: " + " ".join(f"{x:5.0f}" for x in s[i][1])
        print(line)
    np.save('analysis/orig_lpc_env.npy', oe)
