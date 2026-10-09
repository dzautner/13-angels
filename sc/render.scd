// Non-realtime render of the intro to a WAV file (no audio device needed).
//
//   sclang sc/render.scd [out.wav] [params.json] [cycles]
//
// params.json (optional) overrides defaults:
//   { "synth": {...angel args...}, "room": {...}, "score": {...} }
// Result defaults to renders/intro.wav next to this folder.

(
var dir = thisProcess.nowExecutingPath.dirname;
var argv = thisProcess.argv;
var outPath = argv[0] ?? { dir +/+ "../renders/intro.wav" };
var params = (synth: (), room: (), score: ());
var cycles = (argv[2] ? "4").asInteger;
var score, events, fxBus = 16, dur, synthArgs, roomArgs;
var num = { |v| if(v.isString) { v.asFloat } { v.collect(_.asFloat) } };

(dir +/+ "angel.scd").load;
(dir +/+ "intro.scd").load;

argv[1] !? { |path|
	var j = File.readAllString(path).parseJSON;
	[\synth, \room, \score].do { |k|
		j[k.asString] !? { |d| d.keysValuesDo { |key, v| params[k][key.asSymbol] = num.(v) } };
	};
};
synthArgs = params[\synth].asKeyValuePairs;
roomArgs = params[\room].asKeyValuePairs;

File.mkdir(outPath.dirname);
events = ~introEvents.value(cycles, 13, params[\score]);
dur = events.last[0] + 6;

score = Score.new;
~angelDefs.do { |def| score.add([0.0, [\d_recv, def.asBytes]]) };
score.add([0.0, [\g_new, 2, 1, 0]]); // fx group after the default group
score.add([0.01, [\s_new, \angelRoom, 1999, 0, 2, \in, fxBus, \out, 0] ++ roomArgs.asOSCArgArray]);

events.do { |e, i|
	var id = 2000 + i;
	var onset = e[0] + 0.05, freq = e[1], hold = e[2], fall = e[3], pan = e[4], amp = e[5], fallTime = e[6];
	score.add([onset, [\s_new, \angel, id, 0, 1,
		\out, fxBus, \freq, freq, \amp, amp, \pan, pan, \fall, fall, \fallTime, fallTime]
		++ synthArgs.asOSCArgArray]);
	score.add([onset + hold, [\n_set, id, \gate, 0]]);
};
score.add([dur, [\c_set, 0, 0]]);
score.sort;

score.recordNRT(
	outputFilePath: outPath.standardizePath,
	oscFilePath: outPath.standardizePath ++ ".osc", // unique, so parallel renders don't collide
	sampleRate: 44100,
	headerFormat: "WAV",
	sampleFormat: "int24",
	options: ServerOptions.new.numOutputBusChannels_(2),
	duration: dur,
	action: { File.delete(outPath.standardizePath ++ ".osc"); ("rendered: " ++ outPath).postln; 0.exit }
);
)
