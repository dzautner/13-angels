"""Average mel-spectrogram of a chord event (aligned on the 2.5704 s grid),
original vs synth, plus their difference. Also prints a single error number."""
import sys, numpy as np, librosa, matplotlib; matplotlib.use('Agg'); import matplotlib.pyplot as plt
SR = 22050; P, S = 2.5704, 0.38; HOP = 256

def avg_event(path, offset=0.0, n0=4, n1=16, mono=True):
    y, _ = librosa.load(path, sr=SR, duration=S + n1 * P + 3)
    M = librosa.feature.melspectrogram(y=y, sr=SR, n_fft=2048, hop_length=HOP, n_mels=96, fmin=60, fmax=10000)
    L = int(P * SR / HOP); evs = []
    for n in range(n0, n1):
        a = int((S + n * P + offset - 0.15) * SR / HOP)
        evs.append(M[:, a:a + L])
    E = np.mean(evs, 0)
    return 10 * np.log10(E / E.max() + 1e-10)

def err(A, B, floor=-60):
    A = np.maximum(A, floor); B = np.maximum(B, floor)
    return np.sqrt(np.mean((A - B) ** 2))

if __name__ == '__main__':
    syn = sys.argv[1]; out = sys.argv[2] if len(sys.argv) > 2 else 'ref/avgevent.png'
    A = avg_event('ref/orig.wav'); B = avg_event(syn)
    print(f"mel RMS error: {err(A, B):.2f} dB")
    # band x time summary
    mel = librosa.mel_frequencies(n_mels=96, fmin=60, fmax=10000)
    t = np.arange(A.shape[1]) * HOP / SR - 0.15
    for lo, hi in [(60, 200), (200, 500), (500, 1000), (1000, 2000), (2000, 4000), (4000, 10000)]:
        m = (mel >= lo) & (mel < hi)
        row = []
        for t0 in np.arange(-0.15, 2.4, 0.25):
            k = (t >= t0) & (t < t0 + 0.25)
            row.append(np.mean(B[m][:, k]) - np.mean(A[m][:, k]))
        print(f"{lo:5d}-{hi:<5d} synth-orig dB: " + " ".join(f"{v:+5.1f}" for v in row))
    fig, ax = plt.subplots(1, 3, figsize=(24, 7))
    ext = [t[0], t[-1], 0, 96]
    for a, D, title, kw in [(ax[0], A, 'original', dict(vmin=-60, vmax=0)), (ax[1], B, 'synth', dict(vmin=-60, vmax=0)),
                            (ax[2], np.maximum(B, -60) - np.maximum(A, -60), 'synth - original (red = synth louder)', dict(vmin=-15, vmax=15, cmap='RdBu_r'))]:
        im = a.imshow(D, origin='lower', aspect='auto', extent=ext, **kw); a.set_title(title)
        yt = [0, 16, 32, 48, 64, 80, 95]; a.set_yticks(yt); a.set_yticklabels([f"{mel[i]:.0f}" for i in yt])
        plt.colorbar(im, ax=a)
    plt.tight_layout(); plt.savefig(out, dpi=55)
