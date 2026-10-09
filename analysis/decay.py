"""The sigh, up close: pedal pitch and level every 50 ms through the fall,
averaged over events. Pedal is the lowest voice in most chords, so it can be
tracked reliably all the way down."""
import sys, numpy as np, librosa
SR = 22050; P, S = 2.5704, 0.38; ROOT = 283.7

def curves(path, n0=2, n1=16):
    y, _ = librosa.load(path, sr=SR, duration=S + n1 * P + 3)
    hop = 128
    X = np.abs(librosa.stft(y, n_fft=8192, hop_length=hop)); fr = librosa.fft_frequencies(sr=SR, n_fft=8192)
    ts = np.arange(1.2, 2.6, 0.05); P_, L_, B_ = [], [], []
    for n in range(n0, n1):
        if n % 8 == 0: continue          # [-2 0 2] has a voice below the pedal
        o = S + n * P; pit, lev, bri = [], [], []
        prev = ROOT
        for t in ts:
            i = int((o + t) * SR / hop)
            m = (fr > prev * 0.9) & (fr < prev * 1.03)
            k = X[m, i].argmax(); prev = fr[m][k]
            pit.append(12 * np.log2(prev / ROOT)); lev.append(20 * np.log10(X[m, i][k] + 1e-9))
            spec = X[:, i] ** 2
            bri.append(10 * np.log10(spec[(fr > 1000) & (fr < 4000)].sum() / (spec[(fr > 150) & (fr < 1000)].sum() + 1e-12) + 1e-12))
        P_.append(pit); L_.append(lev); B_.append(bri)
    L = np.median(L_, 0); return ts, np.median(P_, 0), L - L[0], np.median(B_, 0)

if __name__ == '__main__':
    t, po, lo, bo = curves('ref/orig.wav'); _, ps, ls, bs = curves(sys.argv[1])
    print("  t   | pedal pitch (st)  | pedal level (dB re 1.2s) | brightness hi/lo (dB)")
    print("      |  orig   synth     |   orig   synth           |  orig  synth")
    for i in range(len(t)):
        print(f"{t[i]:5.2f} | {po[i]:+5.2f}  {ps[i]:+5.2f}     | {lo[i]:+6.1f}  {ls[i]:+6.1f}          | {bo[i]:5.1f} {bs[i]:5.1f}")
