"""Things averages hide: stereo image, event-to-event variation, amplitude
modulation texture, harmonic-to-noise ratio. Original vs synth."""
import sys, numpy as np, librosa, scipy.signal as ss
SR = 22050; P, S = 2.5704, 0.38
BANDS = [(150, 500), (500, 1000), (1000, 2000), (2000, 4000)]

def load(path):
    y, _ = librosa.load(path, sr=SR, mono=False, duration=44)
    return y

def bandpass(x, lo, hi):
    return ss.sosfiltfilt(ss.butter(4, [lo, hi], 'bandpass', fs=SR, output='sos'), x)

def report(path, label):
    y = load(path); mono = y.mean(0)
    hold = lambda n: (int((S + n * P + 0.35) * SR), int((S + n * P + 1.05) * SR))
    evs = [n for n in range(4, 16)]
    out = []
    # stereo correlation and side/mid per band during holds
    for lo, hi in BANDS:
        L, R = bandpass(y[0], lo, hi), bandpass(y[1], lo, hi)
        c, sm = [], []
        for n in evs:
            a, b = hold(n)
            c.append(np.corrcoef(L[a:b], R[a:b])[0, 1])
            sm.append(10 * np.log10(np.mean((L[a:b] - R[a:b]) ** 2) / np.mean((L[a:b] + R[a:b]) ** 2)))
        out.append(f"{lo}-{hi}: LRcorr {np.median(c):.2f} side/mid {np.median(sm):5.1f}dB")
    print(f"{label} stereo   | " + " | ".join(out))
    # event-to-event variation of band levels (dB std across events)
    out = []
    for lo, hi in BANDS:
        x = bandpass(mono, lo, hi); lv = []
        for n in evs:
            a, b = hold(n); lv.append(10 * np.log10(np.mean(x[a:b] ** 2)))
        lv = np.array(lv) - np.linspace(lv[0], lv[-1], len(lv)) * 0  # raw
        d = np.diff(lv)  # neighbour differences (removes the fade-in trend)
        out.append(f"{lo}-{hi}: {np.std(d):.1f}dB")
    print(f"{label} ev-var   | " + " | ".join(out))
    # amplitude-modulation texture: envelope fluctuation 3-30 Hz relative to mean
    out = []
    for lo, hi in BANDS:
        x = bandpass(mono, lo, hi); env = np.abs(ss.hilbert(x))
        env = ss.sosfiltfilt(ss.butter(2, 40, 'low', fs=SR, output='sos'), env)
        m = []
        for n in evs:
            a, b = hold(n); e = env[a:b]
            fast = e - ss.savgol_filter(e, int(0.3 * SR) | 1, 2)
            m.append(np.std(fast) / np.mean(e))
        out.append(f"{lo}-{hi}: {100 * np.median(m):4.1f}%")
    print(f"{label} AM 3-30Hz| " + " | ".join(out))
    # harmonic-to-noise: energy in harmonic peaks vs between, per band
    out = []
    for lo, hi in BANDS:
        r = []
        for n in evs:
            a, b = hold(n); seg = mono[a:b]
            X = np.abs(np.fft.rfft(seg * np.hanning(len(seg)), n=1 << 16)) ** 2; fr = np.fft.rfftfreq(1 << 16, 1 / SR)
            m = (fr >= lo) & (fr < hi); Xm = X[m]
            thr = np.percentile(Xm, 90)
            r.append(10 * np.log10(Xm[Xm >= thr].sum() / Xm[Xm < np.percentile(Xm, 50)].sum()))
        out.append(f"{lo}-{hi}: {np.median(r):5.1f}dB")
    print(f"{label} HNR      | " + " | ".join(out))

def measure(path):
    """Numbers only (mono): HNR dB and AM % per band, over the held parts."""
    mono = load(path).mean(0)
    hold = lambda n: (int((S + n * P + 0.35) * SR), int((S + n * P + 1.05) * SR))
    res = {'hnr': [], 'am': []}
    for lo, hi in BANDS:
        x = bandpass(mono, lo, hi); env = np.abs(ss.hilbert(x))
        env = ss.sosfiltfilt(ss.butter(2, 40, 'low', fs=SR, output='sos'), env)
        m, r = [], []
        for n in range(4, 16):
            a, b = hold(n); e = env[a:b]
            m.append(np.std(e - ss.savgol_filter(e, int(0.3 * SR) | 1, 2)) / np.mean(e))
            seg = mono[a:b]
            X = np.abs(np.fft.rfft(seg * np.hanning(len(seg)), n=1 << 16)) ** 2; fr = np.fft.rfftfreq(1 << 16, 1 / SR)
            Xm = X[(fr >= lo) & (fr < hi)]
            r.append(10 * np.log10(Xm[Xm >= np.percentile(Xm, 90)].sum() / Xm[Xm < np.percentile(Xm, 50)].sum()))
        res['am'].append(100 * np.median(m)); res['hnr'].append(np.median(r))
    return res

if __name__ == '__main__':
    report('ref/orig.wav', 'orig ')
    report(sys.argv[1], 'synth')
