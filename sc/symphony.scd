// "Thirteen Angels" — a symphony for one voice.
//
//   sclang sc/symphony.scd [out.wav] [params.json]
//
// Everything is sung by the angel voice (sc/angel.scd). The piece keeps the
// record's tuning — the pedal at 283.7 Hz — and keeps coming back to its
// 8-chord cycle.
//
//   I.   Standing Guard  (Largo)    the intro, growing into a full choir
//   II.  Whispers        (Scherzo)  breathy vowel arpeggios in canon
//   III. Lament          (Adagio)   chorale, then a soprano solo over it
//   IV.  Ascension       (Finale)   accelerando, up a tone, a major climax,
//                                   and the voices sighing away one by one
//
// Vowels: 0 angel ("Ah" -> "u"), 1 a, 2 eh, 3 ih, 4 oh, 5 uh.

(
var dir = thisProcess.nowExecutingPath.dirname;
var argv = thisProcess.argv;
var outPath = argv[0] ?? { dir +/+ "../renders/symphony.wav" };
var base = (), sc = ();
var num = { |v| if(v.isString) { v.asFloat } { v.collect(_.asFloat) } };
var score = Score.new, id = 4000, fxBus = 16, end = 0;
var root = 283.7, per = 2.5704;
var hz, note, voices, sigh, cycleBass, t0, marks = List.new;

(dir +/+ "angel.scd").load;
(dir +/+ "intro.scd").load;
argv[1] !? { |path|
	var j = File.readAllString(path).parseJSON;
	j["synth"] !? { |d| d.keysValuesDo { |k, v| base[k.asSymbol] = num.(v) } };
	j["score"] !? { |d| d.keysValuesDo { |k, v| sc[k.asSymbol] = num.(v) } };
};
sc = ~introDefaults.copy.putAll(sc);

hz = { |deg| root * deg.midiratio };

// one voice at `deg` semitones from the pedal, released after `hold` s
note = { |t, deg, hold, args|
	var a = base.copy.putAll((freq: hz.(deg), amp: 0.08, out: fxBus,
		fall: 2, fallTime: 0.5, drift: 0.1, pan: (deg / 30).clip(-0.6, 0.6)));
	a.putAll(args ? ());
	score.add([t + 0.1, [\s_new, \angel, id, 0, 1] ++ a.asKeyValuePairs.asOSCArgArray]);
	score.add([t + 0.1 + hold, [\n_set, id, \gate, 0]]);
	id = id + 1; end = max(end, t + hold + 4);
};

// a chord; the top voice lets go first, the others `stagger` s apart
voices = { |t, degs, hold, args, stagger = 0.12|
	degs.sort.reverse.do { |d, rank| note.(t + rrand(0, 0.025), d, hold + (rank * stagger), args) };
};

// the record's release rule: higher voices let go earlier, all land together
sigh = { |t, degs, args, scale = 1|
	degs.do { |d|
		var rel = (sc.relPedal - (sc.relSlope * d)) * scale;
		note.(t - sc.lead, d, rel + sc.lead, (fall: if(d == 0) { sc.depthPedal } { sc.depth },
			fallTime: ((sc.landAt - (sc.relPedal - (sc.relSlope * d))) * scale).max(0.2)).putAll(args ? ()));
	};
};

// a bass line under the record's cycle
cycleBass = [-14, -12, -16, -12, -17, -19, -12, -16];

thisThread.randSeed = 13;

// ------------------------------------------------------------------ I. Standing Guard
t0 = 0.5; marks.add(["I. Standing Guard", t0]);
32.do { |i|
	var t = t0 + (i * per), degs = ~introCycle.wrapAt(i), cyc = i div: 8;
	var top = degs.maxItem, lvl = (0.55 + (i / 32 * 0.45));
	// the record's voices, all the way through
	sigh.(t, degs, (amp: 0.09 * lvl, pan: 0));
	// cycle 2+: a bass line ("oh" closing to "uh")
	if(cyc >= 1) {
		note.(t, cycleBass.wrapAt(i), per - 0.25, (vow: 4, vow2: 5, morph: 2, amp: 0.085 * lvl,
			fall: 1, fallTime: 0.4, attack: 0.3, swellDepth: 0.3, pan: 0));
	};
	// cycle 3+: the melody an octave down, on "a"
	if(cyc >= 2) {
		sigh.(t, [top - 12], (vow: 1, vow2: 4, morph: 1.5, amp: 0.06 * lvl, pan: -0.35));
	};
	// cycle 4: a soprano descant an octave up, on "ih"
	if(cyc >= 3) {
		sigh.(t, [top + 12], (vow: 3, vow2: 0, morph: 0.8, amp: 0.045, pan: 0.35, fall: 5));
		note.(t, top + 7, per - 0.4, (vow: 2, vow2: 1, morph: 1, amp: 0.03, pan: -0.5, fall: 1));
	};
};
// the full choir holds the last chord, then sighs away top-first
voices.(t0 + (32 * per), [-24, -12, -5, 0, 3.2, 7.2, 12, 15.2], 5.5,
	(vow: 1, vow2: 0, morph: 3, amp: 0.07, fall: 3, fallTime: 0.9, attack: 0.4, swell: 2), 0.25);

// ------------------------------------------------------------------ II. Whispers
t0 = t0 + (32 * per) + 10; marks.add(["II. Whispers", t0]);
{
	var e = per / 8;                                   // eighth notes at the record's pulse
	var bars = [[0, 3, 7], [-4, 0, 3], [3, 7, 10], [-2, 2, 5]] ! 3
	++ [[[5, 8, 12], [3, 7, 10], [2, 5, 8], [-5, -1, 2]], [[0, 3, 7], [0, 3, 7]]];
	var pat = [0, 1, 2, 3, 2, 1, 0, 1];
	var melody = [nil, nil, nil, nil, nil, nil, nil, nil,
		12, 10, 8, 7, 10, 12, 14, 10, 15, 14, 12, 8, 10, 15, 17, 14,
		17, 15, 15, 14, 14, 12, 11, 14, 12, nil, nil, nil];
	bars = bars.flatten(1);
	bars.do { |ch, b|
		var tb = t0 + (b * per), tones = ch ++ [ch[0] + 12];
		var thin = b >= 16;                              // coda thins out
		// bass, one long note per bar
		note.(tb, ch[0] - 12 - if(ch[0] > 2) { 12 } { 0 }, per - 0.3,
			(vow: 5, vow2: 4, morph: 1.5, amp: 0.07, fall: 1, attack: 0.2, pan: 0));
		// voice A (left): arpeggio, cycling vowels, sobbing falls
		8.do { |k|
			if(thin.not or: { k.even }) {
				note.(tb + (k * e), tones[pat[k]], 0.17, (vow: (b * 8 + k) % 5 + 1, vow2: (b * 8 + k + 2) % 5 + 1,
					morph: 0.2, amp: 0.05, fall: 4, fallTime: 0.16, attack: 0.02, voiceDelay: 0.01,
					swellDepth: 0, breath: 1.8, pan: -0.6));
			};
		};
		// voice B (right): the same an octave up, three eighths behind, from bar 3
		if(b >= 2 and: { thin.not }) {
			8.do { |k|
				note.(tb + ((k + 3) * e), tones[pat[k]] + 12, 0.14, (vow: 3, vow2: 1, morph: 0.15,
					amp: 0.032, fall: 5, fallTime: 0.14, attack: 0.02, voiceDelay: 0.01, swellDepth: 0,
					breath: 2.2, pan: 0.6));
			};
		};
		// the angel melody, two notes a bar, from bar 5
		2.do { |h|
			melody[(b * 2) + h] !? { |d|
				note.(tb + (h * per / 2), d, (per / 2) - 0.12, (vow: 0, amp: 0.08, fall: 2, fallTime: 0.35, pan: 0.1));
			};
		};
	};
	t0 = t0 + (bars.size * per);
}.value;

// ------------------------------------------------------------------ III. Lament
t0 = t0 + 6; marks.add(["III. Lament", t0]);
{
	var dur = 4.5;
	// S A T B (semitones from the pedal); a suspension on the V
	var chorale = [
		[12, 3, -5, -12],      // i
		[12, 5, -7, -16],      // iv6
		[[12, 11], 2, -5, -17],// V sus4 -> 3
		[7, 3, -9, -12],       // i
		[12, 3, -9, -16],      // VI
		[12, 5, -4, -19],      // iv
		[14, 5, -4, -19],      // ii°6
		[14, 5, -1, -17],      // V7
		[12, 3, -12, -24],     // i
	];
	var solo = [[19], [20], [19, 17], [15], [15, 20], [17], [17, 14], [14, 11], [12]];
	2.do { |pass|
		chorale.do { |ch, c|
			var t = t0 + (((pass * chorale.size) + c) * dur);
			var last = c == (chorale.size - 1);
			var hold = if(last) { dur * 1.6 } { dur - 0.35 };
			var vv = if(pass == 0) { (vow: 4, vow2: 1, morph: 3) } { (vow: 1, vow2: 5, morph: 3.5) };
			ch.do { |d, part|
				var amp = [0.07, 0.065, 0.065, 0.09][part];
				var args = vv.copy.putAll((amp: amp, fall: 1.2, fallTime: 0.6, attack: 0.6,
					swell: 2, swellDepth: 0.5, pan: [0.4, 0.15, -0.15, 0][part]));
				if(d.isArray) {
					// suspension: hold the 4th, resolve to the 3rd half way
					note.(t, d[0], dur / 2, args.copy.put(\fall, 0.3));
					note.(t + (dur / 2), d[1], (dur / 2) - 0.35, args.copy.put(\attack, 0.1));
				} {
					note.(t + (part * 0.04), d, hold - (part * 0.08), args);
				};
			};
			// second pass: a soprano solo above the chorale
			if(pass == 1) {
				var notes = solo[c], n = notes.size;
				notes.do { |d, k|
					var finalNote = last && (k == (n - 1));
					note.(t + (k * dur / n), d, if(finalNote) { dur * 1.4 } { (dur / n) - 0.2 },
						(vow: 0, amp: 0.085, closeStart: 1.2, closeTime: 2, attack: 0.15, pan: 0.05,
							fall: if(finalNote) { -3 } { 2 }, fallTime: if(finalNote) { 1.2 } { 0.45 }));
				};
			};
		};
	};
	t0 = t0 + (2 * chorale.size * dur) + 4;
}.value;

// ------------------------------------------------------------------ IV. Ascension
t0 = t0 + 5; marks.add(["IV. Ascension", t0]);
{
	var t = t0, p, k;
	// A: the cycle an octave down, dark "uh", over a low drone
	note.(t, -24, 8 * per + 26, (vow: 4, vow2: 5, morph: 20, amp: 0.1, attack: 3, swell: 8, fall: 1, pan: 0));
	note.(t + 4, -17, 8 * per + 22, (vow: 5, vow2: 4, morph: 20, amp: 0.07, attack: 3, swell: 8, fall: 1, pan: 0));
	8.do { |i|
		sigh.(t + (i * per), ~introCycle.wrapAt(i) - 12, (vow: 5, vow2: 4, morph: 1, amp: 0.075, pan: 0));
	};
	t = t + (8 * per);
	// B: accelerando, the choir gathering, sighs starting to rise
	p = per; k = 0;
	16.do { |i|
		var degs = ~introCycle.wrapAt(i), lvl = 0.6 + (i / 16 * 0.4), sc2 = p / per;
		sigh.(t, degs, (amp: 0.075 * lvl, pan: 0), sc2);
		sigh.(t, degs - 12, (vow: 1, vow2: 4, morph: 1, amp: 0.05 * lvl, pan: -0.3), sc2);
		note.(t, cycleBass.wrapAt(i), p - 0.15, (vow: 4, amp: 0.08 * lvl, fall: 1, attack: 0.15, pan: 0));
		if(i >= 8) {
			note.(t, degs.maxItem + 12, p * 0.6, (vow: 3, vow2: 1, morph: 0.4, amp: 0.045 * lvl,
				fall: -3, fallTime: p * 0.3, pan: 0.4));
		};
		t = t + p; p = p * 0.965;
	};
	// C: up a whole tone, the full choir
	8.do { |i|
		var degs = ~introCycle.wrapAt(i) + 2;
		voices.(t, (degs - 12) ++ degs ++ [degs.maxItem + 12], 1.6,
			(vow: 1, vow2: 0, morph: 1.2, amp: 0.055, fall: 3, fallTime: 0.45, pan: rrand(-0.4, 0.4)), 0.07);
		note.(t, cycleBass.wrapAt(i) + 2, 1.9, (vow: 4, amp: 0.09, fall: 1, pan: 0));
		t = t + 2.0;
	};
	// the climax: i - VI - VII - I (major), grand voicings over four octaves
	[
		[[-24, -12, -5, 0, 3, 7, 12, 15], 3.6],
		[[-28, -16, -9, -4, 0, 3, 8, 12, 15], 3.6],
		[[-26, -14, -7, -2, 2, 5, 10, 14, 17], 3.6],
		[[-24, -12, -5, 0, 4, 7, 12, 16, 19, 24], 10],
	].do { |row, c|
		var degs = row[0] + 2, dur = row[1], big = c == 3;
		degs.do { |d, v|
			note.(t + (v * 0.02), d, if(big) { dur - (v * 0.5) } { dur - 0.2 },
				(vow: 1, vow2: if(big) { 0 } { 1 }, morph: if(big) { 5 } { 1 },
					amp: if(big) { 0.06 } { 0.055 }, attack: if(big) { 0.5 } { 0.25 }, swell: 2.5,
					fall: if(big) { 4 + (v * 0.3) } { 1.5 }, fallTime: if(big) { 1.2 } { 0.5 },
					pan: (v.linlin(0, degs.size - 1, -0.6, 0.6)) * [1, -1].wrapAt(v)));
		};
		t = t + dur;
	};
	// coda: alone again — the pedal and the record's first chord, sighing once
	t = t + 1.5;
	sigh.(t, [0, 3.2, 7.2], (amp: 0.09, pan: 0));
	t0 = t + 4;
}.value;

// a stereo room for the symphony (the record itself is mono) + a safety limiter
~angelDefs = ~angelDefs ++ [SynthDef(\symphonyRoom, { |in = 0, out = 0, mix = 0.26, room = 0.78, damp = 0.55|
	var dry = In.ar(in, 2), wet;
	wet = FreeVerb2.ar(dry[0], dry[1], 1, room, damp);
	Out.ar(out, Limiter.ar((dry * (1 - mix)) + (wet * mix), 0.9, 0.02));
})];
~angelDefs.do { |def| score.add([0.0, [\d_recv, def.asBytes]]) };
score.add([0.02, [\g_new, 2, 1, 0]]);
score.add([0.05, [\s_new, \symphonyRoom, 3999, 0, 2, \in, fxBus, \out, 0]]);
score.add([end, [\c_set, 0, 0]]);
score.sort;

marks.do { |m| (m[0] ++ " at " ++ m[1].round(0.1) ++ "s").postln };
("total " ++ end.round(0.1) ++ "s, " ++ (id - 4000) ++ " notes").postln;

score.recordNRT(
	outputFilePath: outPath.standardizePath,
	oscFilePath: outPath.standardizePath ++ ".osc",
	sampleRate: 44100, headerFormat: "WAV", sampleFormat: "int24",
	options: ServerOptions.new.numOutputBusChannels_(2).memSize_(65536),
	duration: end,
	action: { File.delete(outPath.standardizePath ++ ".osc"); ("rendered: " ++ outPath).postln; 0.exit }
);
)
