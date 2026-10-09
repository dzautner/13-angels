"""Micro-behaviour of the pedal note (~283.7 Hz) during the held part of each
chord: pitch jitter, amplitude shimmer, partial line width. Original vs synth."""
import sys, numpy as np, librosa, scipy.signal as ss

SR = 22050; P, S = 2.5704, 0.38; ROOT = 283.7

def analytic_band(y, fc, bw):
    sos = ss.butter(4, [fc - bw, fc + bw], 'bandpass', fs=SR, output='sos')
    z = ss.hilbert(ss.sosfiltfilt(sos, y))
    amp = np.abs(z)
    inst_f = np.diff(np.unwrap(np.angle(z))) * SR / (2 * np.pi)
    return amp[1:], inst_f

def stats(path, offset=0.0, harmonics=(1, 2)):
    y, _ = librosa.load(path, sr=SR, duration=44)
    out = {h: [] for h in harmonics}
    for n in range(2, 16):
        if n % 8 == 0:   # skip the [-2 0 2] chord, it crowds the pedal
            continue
        o = S + n * P + offset
        a, b = int((o + 0.35) * SR), int((o + 1.05) * SR)
        for h in harmonics:
            amp, f = analytic_band(y[a - 2000:b + 2000], ROOT * h * 1.005, 14 * h ** 0.5)
            amp, f = amp[2000:-2000], f[2000:-2000]
            k = int(0.15 * SR) | 1
            ft = ss.savgol_filter(f, k, 2); at = ss.savgol_filter(amp, k, 2)   # slow trend
            cents = 1200 * np.log2(np.maximum(f, 1) / np.maximum(ft, 1))
            cents = ss.medfilt(cents, 31)
            shimmer = 20 * np.log10(np.maximum(amp, 1e-9) / np.maximum(at, 1e-9))
            # modulation spectrum of amplitude (what rate is the wobble?)
            A = np.abs(np.fft.rfft((amp / amp.mean() - 1) * np.hanning(len(amp)), n=1 << 16))
            fr = np.fft.rfftfreq(1 << 16, 1 / SR); m = (fr > 1) & (fr < 30)
            out[h].append((np.std(cents), np.std(shimmer), fr[m][A[m].argmax()],
                           np.std(1200 * np.log2(ft / ft.mean()))))
    return {h: np.median(np.array(v), 0) for h, v in out.items()}

def linewidth(path, offset=0.0):
    y, _ = librosa.load(path, sr=SR, duration=45); w = []
    for n in range(2, 16):
        if n % 8 == 0: continue
        o = S + n * P + offset
        seg = y[int((o + 0.35) * SR):int((o + 1.05) * SR)]
        N = 1 << 18; X = np.abs(np.fft.rfft(seg * np.hanning(len(seg)), n=N)); fr = np.fft.rfftfreq(N, 1 / SR)
        m = (fr > ROOT * 0.97) & (fr < ROOT * 1.04); Xm = X[m]; pk = Xm.argmax()
        above = np.where(Xm > Xm[pk] / 2)[0]
        w.append(fr[m][above[-1]] - fr[m][above[0]])
    return np.median(w)

if __name__ == '__main__':
    for label, path, off in [('orig ', 'ref/orig.wav', 0.0), ('synth', sys.argv[1], float(sys.argv[2]) if len(sys.argv) > 2 else 0.0)]:
        st = stats(path, off)
        for h, (jit, shim, rate, drift) in st.items():
            print(f"{label} H{h}: jitter {jit:5.1f} cents | shimmer {shim:4.2f} dB | AM peak {rate:4.1f} Hz | slow pitch movement {drift:4.1f} cents")
        print(f"{label} pedal line width (-6dB, 0.7s window): {linewidth(path, off):.2f} Hz")
