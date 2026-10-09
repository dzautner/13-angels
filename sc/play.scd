// 13 angels on the desktop.
// Open in the SuperCollider IDE and evaluate the blocks one at a time
// (cursor inside the parentheses, Cmd/Ctrl+Enter).

// 1. boot, load the voice, start the room
(
var dir = thisProcess.nowExecutingPath.dirname;
(dir +/+ "angel.scd").load;
(dir +/+ "intro.scd").load;
s.waitForBoot {
	~angelDefs.do(_.add);
	s.sync;
	~fxBus = Bus.audio(s, 2);
	~room = Synth.tail(s, \angelRoom, [\in, ~fxBus, \out, 0]);
};
)

// 2. play the intro, looping
(
~intro = Routine {
	var t = 0;
	loop {
		~introEvents.value(1, 999.rand).do { |e|
			var onset = e[0] - ~introStart;
			(onset - t).max(0).wait; t = onset;
			fork {
				var x = Synth(\angel, [\out, ~fxBus, \freq, e[1], \fall, e[3],
					\pan, e[4], \amp, 0.25, \fallTime, e[6]]);
				e[2].wait;
				x.set(\gate, 0);
			};
		};
		(~introCycle.size * ~introPeriod - t).wait; t = 0;
	};
}.play;
)
~intro.stop;

// 3. play it from a MIDI keyboard. Releasing a key makes the note sigh,
//    so let go of the top note first and the rest just after.
(
var notes = ();
MIDIClient.init; MIDIIn.connectAll;
MIDIdef.noteOn(\angelOn, { |vel, num|
	notes[num] !? { |x| x.set(\gate, 0) };
	notes[num] = Synth(\angel, [\out, ~fxBus, \freq, num.midicps, \amp, 0.3 * (vel / 127),
		\pan, rrand(-0.4, 0.4)]);
});
MIDIdef.noteOff(\angelOff, { |vel, num|
	notes.removeAt(num) !? { |x| x.set(\gate, 0) };
});
)

// a single angel, by hand
x = Synth(\angel, [\out, ~fxBus, \freq, 283.7 * 7.2.midiratio, \fall, 6, \fallTime, 1]);
x.set(\gate, 0);

// one of the record's chords, top voice letting go first
(
fork {
	var xs = [0, 3.2, 7.2].collect { |d| Synth(\angel, [\out, ~fxBus, \freq, 283.7 * d.midiratio]) };
	1.2.wait;
	xs.reverse.do { |x| x.set(\gate, 0); 0.16.wait };
};
)
