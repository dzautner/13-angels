"""When does each voice start to fall, how far, how long? Track the strongest
peak near each voice's pitch through each event."""
import sys, numpy as np, librosa
SR = 22050; P, S = 2.5704, 0.38; ROOT = 283.7
CYCLE = [[-2.0, 0, 2.05], [0, 3.2], [0, 5.2, 8.1], [0, 3.2, 7.2], [0, 7.2], [0, 5.2, 10.2], [0, 3.2, 7.2], [0, 5.2, 8.1]]

def run(path, n0=2, n1=16, offset=0.0, quiet=False):
    y, _ = librosa.load(path, sr=SR, duration=S + n1 * P + 3)
    hop = 128
    X = np.abs(librosa.stft(y, n_fft=8192, hop_length=hop)); fr = librosa.fft_frequencies(sr=SR, n_fft=8192)
    res = {'pedal': [], 'top': []}
    for n in range(n0, n1):
        degs = CYCLE[n % 8]
        o = S + n * P + offset
        for role, deg in [('pedal', 0), ('top', max(degs))]:
            if role == 'top' and max(degs) == 0: continue
            if role == 'pedal' and n % 8 == 0: continue
            f0 = ROOT * 2 ** (deg / 12)
            # use the 2nd harmonic for the pedal when crowded? fundamental is fine here
            track = []; ts = np.arange(0.3, 2.45, hop / SR)
            prev = f0
            for t in ts:
                i = int((o + t) * SR / hop)
                m = (fr > prev * 0.88) & (fr < prev * 1.03)
                spec = X[m, i]
                if spec.max() < X[:, i].max() * 0.02: track.append(np.nan); continue
                prev = fr[m][spec.argmax()]; track.append(prev)
            track = np.array(track)
            st = 12 * np.log2(track / f0)
            hold = np.nanmedian(st[(ts > 0.5) & (ts < 0.9)])
            below = np.where((st < hold - 0.4) & (ts > 0.7))[0]
            if len(below) == 0: continue
            t_start = ts[below[0]]
            valid = ~np.isnan(st)
            depth = hold - np.nanmin(st[ts > t_start]) if np.any(valid & (ts > t_start)) else np.nan
            end = ts[valid][-1]
            res[role].append((t_start, depth, end))
    summary = {role: np.median(np.array(v), 0) for role, v in res.items()}
    if quiet: return summary
    for role, v in res.items():
        v = np.array(v)
        print(f"{role:5s}: fall starts {np.median(v[:,0]):.2f}s (IQR {np.percentile(v[:,0],25):.2f}-{np.percentile(v[:,0],75):.2f}) | depth {np.median(v[:,1]):.1f} st (IQR {np.percentile(v[:,1],25):.1f}-{np.percentile(v[:,1],75):.1f}) | audible until {np.median(v[:,2]):.2f}s")

if __name__ == '__main__':
    print('original:'); run('ref/orig.wav')
    if len(sys.argv) > 1: print('synth:'); run(sys.argv[1])
