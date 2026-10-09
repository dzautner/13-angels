// 13 angels — the "angel" voice.
//
// Built from spectral analysis of the intro of A Silver Mt. Zion's
// "13 Angels Standing Guard 'Round The Side Of Your Bed" (0:00–1:20):
//
//  * it's a "Hauuu": an "h" breath just before the voice, an open "ha" that
//    closes to "uu" over ~1.5s, and a little exhale after the sigh. A frozen
//    vowel is what makes it sound like a trumpet.
//  * the energy lives below ~2kHz; anything much above that reads as buzz.
//  * each note scoops in slightly flat and wanders/creeps sharp (~10 cents of
//    slow movement) while held. No real vibrato.
//  * soft fade-in, slow swell; on release the pitch "sighs" down and lands
//    (the pedal ~2.7 semitones in ~0.35s), still singing, then the note stops
//    cleanly within ~0.3s. Higher voices let go earlier (~70ms per semitone).
//  * mono, short room; a low rumble under each note that comes and goes with it.
//
// The defaults are tuned by analysis/optimize.py, which renders this file
// offline and scores it against the record (event-averaged mel spectrogram).
// Loading this file defines ~angelDefaults, ~angelVowels and ~angelDefs
// without touching the server.

// Formants: [F1, F2, F3], [B1, B2, B3] (Hz), [A1, A2, A3] (linear).
// The "angel" vowel (index 0) moves from `open` ("ha") to `closed` ("uu").
~angelDefaults = (
	openF: [670.2, 1020, 2214], openB: [350.3, 385.7, 497.9], openA: [1, 1.001, 0.2982],
	closedF: [431.2, 950.9, 2006], closedB: [274.9, 230.7, 600], closedA: [1, 0.1541, 0.01807],
	tilt: 0.7404, hiCut: 4279,
	closeTime: 0.8103, closeMid: 0.2587, closeStart: 0.396,
	voiceDelay: 0.01411, attack: 0.3978, swell: 0.7239, swellDepth: 0.5108,
	fall: 3, fallTime: 0.4, fallLevel: 0.4059, fallCurve: -1.046, cutTime: 0.3491, cutCurve: -3.273,
	scoop: 0.0008164, drift: 0.01024, wander: 0.02268, wanderRate: 1.583, vib: 0.01109,
	jitter: 0.0086, shimmer: 0.971,
	breath: 0.6335, bed: 0.2777, hLevel: 0.1807, exhale: 0.6999, noiseHi: 803.3,
	rumble: 0.2298, rumbleFreq: 289.5, midBreath: 0.1553, midFreq: 1252, midQ: 1.104, shimmerTilt: 1.054,
	unison: 8.335, uniMix: 0.0419,
	fallDark: 1.469, fallWobble: 0.0002881, fallShape: 0.9322,
);

// Classic vowels for the norns UI; index 0 is a placeholder for the angel.
~angelVowels = [
	[~angelDefaults.openF, ~angelDefaults.openB, ~angelDefaults.openA],
	[[750, 1300, 2700], [130, 140, 200], [1.0, 0.6, 0.12]],   // a
	[[450, 2000, 2800], [110, 160, 200], [1.0, 0.3, 0.15]],   // eh
	[[330, 2300, 2900], [90, 180, 220], [1.0, 0.18, 0.12]],   // ih
	[[450, 900, 2700], [120, 130, 200], [1.0, 0.5, 0.06]],    // oh
	[[340, 860, 2600], [100, 120, 200], [1.0, 0.25, 0.04]],   // uh
];

~angelDefs = [

	SynthDef(\angel, {
		|out = 0, freq = 285, amp = 0.2, gate = 1, pan = 0,
		vow = 0, vow2 = 0, morph = 0.3|

		var d = ~angelDefaults;
		var openF = \openF.kr(d.openF), openB = \openB.kr(d.openB), openA = \openA.kr(d.openA);
		var closedF = \closedF.kr(d.closedF), closedB = \closedB.kr(d.closedB), closedA = \closedA.kr(d.closedA);
		var tilt = \tilt.kr(d.tilt), hiCut = \hiCut.kr(d.hiCut);
		var closeTime = \closeTime.kr(d.closeTime), closeMid = \closeMid.kr(d.closeMid), closeStart = \closeStart.kr(d.closeStart);
		var voiceDelay = \voiceDelay.kr(d.voiceDelay), attack = \attack.kr(d.attack);
		var swell = \swell.kr(d.swell), swellDepth = \swellDepth.kr(d.swellDepth);
		var fall = \fall.kr(d.fall), fallTime = \fallTime.kr(d.fallTime);
		var fallLevel = \fallLevel.kr(d.fallLevel), fallCurve = \fallCurve.kr(d.fallCurve);
		var cutTime = \cutTime.kr(d.cutTime), cutCurve = \cutCurve.kr(d.cutCurve);
		var scoop = \scoop.kr(d.scoop), drift = \drift.kr(d.drift);
		var wander = \wander.kr(d.wander), wanderRate = \wanderRate.kr(d.wanderRate), vib = \vib.kr(d.vib);
		var jitter = \jitter.kr(d.jitter), shimmerAmt = \shimmer.kr(d.shimmer);
		var breath = \breath.kr(d.breath), bed = \bed.kr(d.bed), hLevel = \hLevel.kr(d.hLevel);
		var exhale = \exhale.kr(d.exhale), noiseHi = \noiseHi.kr(d.noiseHi);
		var rumble = \rumble.kr(d.rumble), rumbleFreq = \rumbleFreq.kr(d.rumbleFreq);
		var midBreath = \midBreath.kr(d.midBreath), midFreq = \midFreq.kr(d.midFreq), midQ = \midQ.kr(d.midQ);
		var shimmerTilt = \shimmerTilt.kr(d.shimmerTilt);
		var unison = \unison.kr(d.unison), uniMix = \uniMix.kr(d.uniMix);
		var fallDark = \fallDark.kr(d.fallDark), fallWobble = \fallWobble.kr(d.fallWobble);
		var fallShape = \fallShape.kr(d.fallShape);
		var f2;

		var nh = 20, closing, angel, table, vowNow, fm, bw, fa, f, pitchEnv, fallEnv,
		env, life, hEnv, gains, sig, noise;

		// --- the angel's "ha" -> "uu"
		// stays open ("ah") for `closeStart`, then glides to "u" over `closeTime`
		closing = EnvGen.kr(Env([0, 0, closeMid, 1], [closeStart, 0.5 * closeTime, 0.5 * closeTime], [0, 0, \sin]));
		angel = ([openF, openB, openA].flat * (1 - closing)) + ([closedF, closedB, closedA].flat * closing);

		// --- vowel: morph from vow to vow2 over `morph` seconds
		vowNow = vow + ((vow2 - vow) * EnvGen.kr(Env([0, 1], [morph], \sin)));
		table = ([angel] ++ ~angelVowels[1..].collect(_.flat)).flop;
		table = table.collect { |row| LinSelectX.kr(vowNow, row) };
		fm = table[0..2]; bw = table[3..5]; fa = table[6..8];

		// --- pitch: scoop in, creep sharp, wander, sigh down on release
		pitchEnv = EnvGen.kr(Env([scoop.neg, 0], [0.3], \sin))
		+ (drift * EnvGen.kr(Env([0, 1], [1.6], -2)))
		+ LFNoise2.kr(wanderRate, wander)
		+ (SinOsc.kr(4.6, 0, vib) * EnvGen.kr(Env([0, 0, 1], [0.5, 1])));
		fallEnv = EnvGen.kr(Env([0, 0.12, 1], [0.15, 0.85] * fallTime, [2, fallShape]), 1 - gate);
		// the voice gets a little unsteady while it slides
		f = freq * (pitchEnv - (fall * fallEnv)
			+ (LFNoise2.kr(6, fallWobble) * (fallEnv * (1 - fallEnv) * 4))).midiratio;
		f = f * (1 + LFNoise1.kr(23, jitter));

		// --- amplitude: voice enters `voiceDelay` after the "h" and swells.
		// On release it keeps singing through the fall (losing ~9dB), lands,
		// then stops quickly — like running out of breath — rather than
		// trailing off. On the record the last 45dB go in ~0.3s.
		env = EnvGen.kr(
			Env([0, 0, 1 - swellDepth, 1, fallLevel, 0], [voiceDelay, attack, swell, fallTime, cutTime],
				[0, 2, -1, fallCurve, cutCurve], releaseNode: 3),
			gate
		);
		life = EnvGen.kr(Env([1, 1, 0], [0, fallTime + cutTime + 0.6], releaseNode: 1), gate, doneAction: Done.freeSelf);

		// --- breath: "h" onset, then the exhale after the sigh
		hEnv = EnvGen.kr(Env([0, 1, 0.35], [0.04, 0.25], [2, -3]))
		+ EnvGen.kr(Env([0, 0, exhale, 0], [fallTime * 0.85, 0.15, 1.1], [0, 2, -3]), 1 - gate);

		// --- additive voice: harmonic k gets the formant-curve gain at k*f
		gains = (1..nh).collect { |k|
			var fk = f * k;
			var g = 3.collect { |i| fa[i] / (1 + ((fk - fm[i]) / (bw[i] * 0.5)).squared) }.sum;
			// and darkens as it falls
			g * (fk < 16000) * (k ** (tilt + (fallDark * fallEnv)).neg) / (1 + (fk / hiCut).squared)
		};
		gains = gains / (gains.squared.sum.sqrt + 1e-6);

		// an optional second singer a few cents away (barely used: measurements
		// say the record is one steady voice per part, not an ensemble)
		f2 = f * ((unison * (1 + LFNoise2.kr(0.35, 0.5))) / 1200).midiratio * (1 + LFNoise1.kr(19, jitter));
		sig = (1..nh).collect { |k, i|
			var sh = 1 + (LFNoise1.kr(Rand(6, 14)) * ((k / nh) ** shimmerTilt) * shimmerAmt);
			var sh2 = 1 + (LFNoise1.kr(Rand(6, 14)) * ((k / nh) ** shimmerTilt) * shimmerAmt);
			((SinOsc.ar(f * k, Rand(0, 2pi)) * sh) + (SinOsc.ar(f2 * k, Rand(0, 2pi)) * sh2 * uniMix))
			* gains[i] / (1 + uniMix)
		}.sum;

		// --- aspiration: noise through the same formants, so the breath
		// itself says "h-a-u"
		noise = WhiteNoise.ar;
		noise = 3.collect { |i| BPF.ar(noise, fm[i], (bw[i] * 1.5 / fm[i]).min(2)) * fa[i] }.sum
		+ (BPF.ar(noise, noiseHi, 1.0) * 0.5);
		noise = noise * breath * ((env * bed) + (hEnv * hLevel));
		// the record's breath is concentrated in the mids, around ~0.5–1kHz
		noise = noise + (BPF.ar(WhiteNoise.ar, midFreq, midQ) * midBreath * env);
		// low body/breath rumble — on the record it comes and goes with the notes
		noise = noise + (LPF.ar(LPF.ar(PinkNoise.ar, rumbleFreq), rumbleFreq) * rumble * env);

		sig = ((sig * env) + noise) * amp * life;
		Out.ar(out, Pan2.ar(sig, pan));
	}),

	// Mono room (the record is essentially mono here) with a gated wash:
	// the reverb blooms while the voices sing, and an envelope follower on
	// the dry voices closes it as they stop, so the clean end of each sigh
	// isn't smeared by a tail.
	SynthDef(\angelRoom, {
		|in = 0, out = 0, mix = 0.2174, room = 0.8546, damp = 0.2866,
		gateThresh = 0.003667, gateRel = 0.07783, gateFloor = 0.04637|
		var dry = In.ar(in, 2).sum, wet, follow, gate;
		wet = FreeVerb.ar(dry, 1, room, damp);
		follow = Amplitude.kr(dry, 0.01, gateRel);
		gate = (follow / gateThresh).clip(0, 1).squared.max(gateFloor);
		Out.ar(out, ((dry * (1 - mix)) + (wet * mix * gate)) ! 2);
	}),

];
