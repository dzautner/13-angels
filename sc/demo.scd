// "What else can it do" — a short piece for the angel voice, rendered offline.
//
//   sclang sc/demo.scd [out.wav] [params.json]
//
// Vowels: 0 angel ("Ah" -> "u"), 1 a, 2 eh, 3 ih, 4 oh, 5 uh.
// Each note can morph from `vow` to `vow2` over `morph` seconds, and a
// negative `fall` makes the release sigh *upwards*.

(
var dir = thisProcess.nowExecutingPath.dirname;
var argv = thisProcess.argv;
var outPath = argv[0] ?? { dir +/+ "../renders/demo.wav" };
var base = ();
var num = { |v| if(v.isString) { v.asFloat } { v.collect(_.asFloat) } };
var score = Score.new, id = 3000, fxBus = 16, end = 0;
var note, chord, m = { |midi| midi.midicps };

(dir +/+ "angel.scd").load;
(dir +/+ "intro.scd").load;
argv[1] !? { |path|
	var j = File.readAllString(path).parseJSON;
	j["synth"] !? { |d| d.keysValuesDo { |k, v| base[k.asSymbol] = num.(v) } };
};

// one voice: starts at t, lets go after `hold` seconds
note = { |t, freq, hold, args|
	var a = base.copy.putAll((freq: freq, amp: 0.12, out: fxBus)).putAll(args ? ());
	score.add([t + 0.1, [\s_new, \angel, id, 0, 1] ++ a.asKeyValuePairs.asOSCArgArray]);
	score.add([t + 0.1 + hold, [\n_set, id, \gate, 0]]);
	id = id + 1; end = max(end, t + hold + 3);
};
// a chord, top voice letting go first (like the record)
chord = { |t, midis, hold, args, stagger = 0.12|
	midis.sort.reverse.do { |mi, rank| note.(t + rrand(0, 0.03), m.(mi), hold + (rank * stagger), args) };
};

thisThread.randSeed = 7;

// 1. vowel chorale (0–17 s): four parts, low bass to soprano; every chord
//    morphs between vowels, with gentle 1–2 semitone sighs
[
	[[45, 57, 64, 72], 4, 1, 0.5],   // Am   "oh" -> "a"
	[[41, 57, 65, 69], 1, 2, 0.5],   // F    "a"  -> "eh"
	[[48, 55, 64, 72], 3, 5, 0.8],   // C    "ih" -> "uh"
	[[43, 59, 62, 71], 2, 4, 0.8],   // G    "eh" -> "oh"
	[[40, 55, 64, 71], 0, 0, 0.5],   // Em   the angel
	[[45, 57, 64, 69], 5, 1, 1.5],   // Am   "uh" -> "a", slowly
].do { |row, i|
	chord.(i * 2.8, row[0], 2.3, (vow: row[1], vow2: row[2], morph: row[3],
		fall: rrand(1.0, 2.0), fallTime: 0.5, amp: 0.1, attack: 0.25));
};

// 2. rising angels (16–29 s): high "ih" voices whose sighs go *up*
[[76, 79, 83], [74, 79, 81], [72, 76, 79], [71, 74, 79], [72, 76, 81]].do { |c, i|
	chord.(16 + (i * 2.4), c, 1.4, (vow: 3, vow2: 3, fall: -5, fallTime: 0.9,
		amp: 0.07, breath: 1.2, pan: rrand(-0.5, 0.5)), 0.2);
};

// 3. whisper canon (28–42 s): breathy short notes cycling a-e-i-o-u,
//    three voices in canon, deep sob-like falls
3.do { |v|
	var line = [69, 72, 76, 74, 72, 71, 69, 67, 69, 72, 74, 76, 79, 76, 74, 72];
	line.do { |mi, i|
		note.(28 + (v * 1.1) + (i * 0.55), m.(mi - (v * 12 / 2).round),
			0.35, (vow: i % 5 + 1, vow2: (i + 2) % 5 + 1, morph: 0.3, fall: 7, fallTime: 0.35,
				breath: 2.5, amp: 0.08, attack: 0.04, pan: [-0.7, 0, 0.7][v]));
	};
};

// 4. monks and angels (41–60 s): a low "oh"/"uh" drone, and the record's
//    sighing motif coming back on top as a coda
[33, 40].do { |mi, i|
	note.(41, m.(mi), 17, (vow: 4, vow2: 5, morph: 8, fall: 1, fallTime: 2,
		amp: 0.16, swell: 4, attack: 1.5, breath: 0.3));
};
~introEvents.value(1, 13).do { |e|
	if(e[0] < 18) {
		note.(44 + e[0], e[1], e[2], (fall: e[3], fallTime: e[6], amp: e[5] * 0.6))
	};
};

// the record is mono, but this piece uses the stereo field: a stereo room
~angelDefs = ~angelDefs ++ [SynthDef(\demoRoom, { |in = 0, out = 0, mix = 0.3, room = 0.6, damp = 0.6|
	var dry = In.ar(in, 2);
	Out.ar(out, (dry * (1 - mix)) + (FreeVerb2.ar(dry[0], dry[1], 1, room, damp) * mix));
})];
~angelDefs.do { |def| score.add([0.0, [\d_recv, def.asBytes]]) };
score.add([0.02, [\g_new, 2, 1, 0]]);
score.add([0.05, [\s_new, \demoRoom, 2999, 0, 2, \in, fxBus, \out, 0]]);
score.add([end, [\c_set, 0, 0]]);
score.sort;

score.recordNRT(
	outputFilePath: outPath.standardizePath,
	oscFilePath: outPath.standardizePath ++ ".osc",
	sampleRate: 44100, headerFormat: "WAV", sampleFormat: "int24",
	options: ServerOptions.new.numOutputBusChannels_(2),
	duration: end,
	action: { File.delete(outPath.standardizePath ++ ".osc"); ("rendered: " ++ outPath).postln; 0.exit }
);
)
