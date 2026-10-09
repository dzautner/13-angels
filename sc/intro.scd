// The opening of "13 Angels…", transcribed from spectral analysis.
//
// The intro is a steady pulse — one chord every 2.5704 s (~23.3 bpm) —
// cycling through 8 chords over a pedal note. The pedal sits at ~283.7 Hz
// on the record (a little under a quarter-tone above C#4). The top voice
// carries the melody: 2 - 3 - 8 - 7 - 7 - 10 - 7 - 8.
//
// Semitones are relative to the pedal, with the slightly wide intervals the
// players actually use (the minor third is ~3.2, the fifth ~7.2, ...).
//
// Loading this file defines ~introRoot, ~introPeriod, ~introCycle and
// ~introEvents.

~introRoot = 283.7;
~introPeriod = 2.5704;
~introStart = 0.38;

~introCycle = [
	[-2.0, 0, 2.05],
	[0, 3.2],
	[0, 5.2, 8.1],
	[0, 3.2, 7.2],
	[0, 7.2],
	[0, 5.2, 10.2],
	[0, 3.2, 7.2],
	[0, 5.2, 8.1],
];

// Timing of the performance (tuned by analysis/optimize.py).
//
// On the record every voice lets go at a time set by its pitch: the pedal
// always starts falling ~1.75 s after the beat, and each semitone above it
// lets go ~75 ms earlier (a +8 top voice at ~1.15 s, a -2 voice at ~1.9 s).
~introDefaults = (
	lead: 0.2996,          // events start this long before the beat (the "h")
	relPedal: 1.618,      // pedal releases this long after the beat
	relSlope: 0.07001,     // ...and each semitone higher releases this much earlier
	relJitter: 0.03,
	depthPedal: 2.533,     // the pedal sighs ~2.7 semitones and lands
	depth: 3.162,          // the other voices' typical sigh depth (semitones)
	depthSpread: 0.5,
	landAt: 1.861,        // ...and every voice lands together, this long after the beat,
	                     // then they all stop (so the top voice slides ~0.8s, the pedal ~0.4s)
	upperAmp: 0.5988,       // non-pedal voices relative to the pedal
);

// Expand into per-voice events: [onset, freq, holdTime, fall, pan, amp, fallTime].
~introEvents = { |cycles = 4, seed = 13, p|
	var events = List.new;
	p = ~introDefaults.copy.putAll(p ? ());
	thisThread.randSeed = seed;
	(cycles * ~introCycle.size).do { |i|
		var degs = ~introCycle.wrapAt(i), n = degs.size;
		var beat = ~introStart + (i * ~introPeriod);
		var onset = beat - p.lead;
		// the record fades in over the first ~40 s
		var level = (beat / 40).clip(0.2, 1.0).sqrt;
		degs.do { |deg, k|
			var release = (p.relPedal - (p.relSlope * deg) + rrand(p.relJitter.neg, p.relJitter)) + p.lead;
			var isPedal = deg == 0;
			var fall = if(isPedal) { p.depthPedal } { p.depth } + rrand(p.depthSpread.neg, p.depthSpread);
			var pan = 0; // the record is mono
			events.add([
				onset + rrand(0.0, 0.02),
				~introRoot * deg.midiratio,
				release,
				fall,
				pan,
				0.2 * level * if(isPedal) { 1 } { p.upperAmp },
				(p.landAt - (p.relPedal - (p.relSlope * deg))).max(0.2)
			]);
		};
	};
	events.sort { |a, b| a[0] < b[0] };
};
