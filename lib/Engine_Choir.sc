Engine_Choir : CroneEngine {
  var pg;
  var amp=0.3;
  var attack=2;
  var release=0.01;
  var delay=0.3;
  var notes;
  *new { arg context, doneCallback;
    ^super.new(context, doneCallback);
  }

  alloc {
    notes = Dictionary.new;
    pg = ParGroup.tail(context.xg);

    SynthDef(\choir,{
      | vel=1,fq=880,bend=0,gate=1,vow=0,attack=2 |
      var a,b,c,d,e,
      vib1,vib2,vib3,vib4,vib5,vib6,vib7,vib8,
      gen1,gen2,gen3,gen4,gen5,gen6,gen7,gen8,ngen, env,
      ah1,eh1,ih1,oh1,uh1,
      ah2,eh2,ih2,oh2,uh2,
      ah3,eh3,ih3,oh3,uh3,
      ah4,eh4,ih4,oh4,uh4,
      mod1,mod2,mod3,mod4,mod5,mod6,mod7,mod8,
      pan1,pan2,pan3,pan4,pan5,pan6,pan7,pan8, mixed_pans;

      vib1=SinOsc.ar(5,0,EnvGen.kr(Env([0,2],[0.2],4),1));
      vib2=SinOsc.ar(5.2,0,EnvGen.kr(Env([0,1],[0.3],4),1));
      vib3=SinOsc.ar(4.3,0,EnvGen.kr(Env([0,2],[0.4],4),1));
      vib4=SinOsc.ar(5.4,0,EnvGen.kr(Env([0,1],[0.5],4),1));
      vib5=SinOsc.ar(4.5,0,EnvGen.kr(Env([0,2],[0.6],4),1));
      vib6=SinOsc.ar(5.25,0,EnvGen.kr(Env([0,1],[0.7],4),1));
      vib7=SinOsc.ar(4.35,0,EnvGen.kr(Env([0,2],[0.8],4),1));
      vib8=SinOsc.ar(5.45,0,EnvGen.kr(Env([0,1],[0.9],4),1));

      mod1=SinOsc.ar(0.1,mul:1);
      mod2=SinOsc.ar(-0.23,mul:1);
      mod3=SinOsc.ar(0.34,mul:1);
      mod4=SinOsc.ar(-0.44,mul:1);
      mod5=SinOsc.ar(0.5,mul:1);
      mod6=SinOsc.ar(-0.6,mul:1);
      mod7=SinOsc.ar(0.73,mul:1);
      mod8=SinOsc.ar(-0.81,mul:1);

      gen1=LFPulse.ar(fq+mod1+vib1,0,0.4*mod8/8+0.2,0.15,0);
      gen2=LFPulse.ar(fq+mod2+vib2,0,0.4*mod7/8+0.2,0.15,0);

      gen5=LFPulse.ar(fq+mod5+vib5,0,0.4*mod4/8+0.2,0.15,0);
      gen6=LFPulse.ar(fq+mod6+vib6,0,0.4*mod3/8+0.2,0.15,0);

      ngen=Pulse.ar(220)*GrayNoise.ar(0.0);

      //Female vowel charts.

      ah1=BBandPass.ar(gen1, 751,0.075) + BBandPass.ar(gen1, 1460,0.075) + BBandPass.ar(gen1, 2841,0.075);
      eh1=BBandPass.ar(gen1, 431,0.075) + BBandPass.ar(gen1, 2241,0.075) + BBandPass.ar(gen1, 2871,0.075);
      ih1=BBandPass.ar(gen1, 329,0.075) + BBandPass.ar(gen1, 2316,0.075) + BBandPass.ar(gen1, 2796,0.075);
      oh1=BBandPass.ar(gen1, 438,0.075) + BBandPass.ar(gen1, 953,0.075) + BBandPass.ar(gen1, 2835,0.075);
      uh1=BBandPass.ar(gen1, 350,0.075) +BBandPass.ar(gen1, 1048,0.075) + BBandPass.ar(gen1, 2760,0.075);

      ah2=BBandPass.ar(gen2, 751,0.075) + BBandPass.ar(gen2, 1460,0.075) + BBandPass.ar(gen2, 2841,0.075);
      eh2=BBandPass.ar(gen2, 431,0.075) + BBandPass.ar(gen2, 2241,0.075) + BBandPass.ar(gen2, 2871,0.075);
      ih2=BBandPass.ar(gen2, 329,0.075) + BBandPass.ar(gen2, 2316,0.075) + BBandPass.ar(gen2, 2796,0.075);
      oh2=BBandPass.ar(gen2, 438,0.075) + BBandPass.ar(gen2, 953,0.075) + BBandPass.ar(gen2, 2835,0.075);
      uh2=BBandPass.ar(gen2, 350,0.075) + BBandPass.ar(gen2, 1048,0.075) + BBandPass.ar(gen2, 2760,0.075);

      //Male vowel charts

      ah3=BBandPass.ar(gen5, 608,0.075) + BBandPass.ar(gen5, 1309,0.075) + BBandPass.ar(gen5, 2466,0.075);
      eh3=BBandPass.ar(gen5, 372,0.075) + BBandPass.ar(gen5, 1879,0.075) + BBandPass.ar(gen5, 2486,0.075);
      ih3=BBandPass.ar(gen5, 290,0.075) + BBandPass.ar(gen5, 1986,0.075) + BBandPass.ar(gen5, 2493,0.075);
      oh3=BBandPass.ar(gen5, 380,0.075) + BBandPass.ar(gen5, 907,0.075) + BBandPass.ar(gen5, 2415,0.075);
      uh3=BBandPass.ar(gen5, 309,0.075) + BBandPass.ar(gen5, 961,0.075) + BBandPass.ar(gen5, 2366,0.075);

      ah4=BBandPass.ar(gen6, 608,0.075) + BBandPass.ar(gen6, 1309,0.075) + BBandPass.ar(gen6, 2466,0.075);
      eh4=BBandPass.ar(gen6, 372,0.075) + BBandPass.ar(gen6, 1879,0.075) + BBandPass.ar(gen6, 2486,0.075);
      ih4=BBandPass.ar(gen6, 290,0.075) + BBandPass.ar(gen6, 1986,0.075) + BBandPass.ar(gen6, 2493,0.075);
      oh4=BBandPass.ar(gen6, 380,0.075) + BBandPass.ar(gen6, 907,0.075) + BBandPass.ar(gen6, 2415,0.075);
      uh4=BBandPass.ar(gen6, 309,0.075) + BBandPass.ar(gen6, 961,0.075) + BBandPass.ar(gen6, 2366,0.075);

      //Summing them all

      a = Mix.new([ah1, ah2, ah3, ah4]);
      b = Mix.new([eh1, eh2, eh3, eh4]);
      c = Mix.new([ih1, ih2, ih3, ih4]);
      d = Mix.new([oh1, oh2, oh3, oh4]);
      e = Mix.new([uh1, uh2, uh3, uh4]);

      //Panning and adding crossfading bwteeen vowels.


      pan1=Pan2.ar(LinSelectX.ar(vow, [a,b,c,d,e],0), -1,1);
      pan2=Pan2.ar(LinSelectX.ar(vow, [a,b,c,d,e],0), -0.8,1);
      pan3=Pan2.ar(LinSelectX.ar(vow, [a,b,c,d,e],0), -0.6,1);
      pan4=Pan2.ar(LinSelectX.ar(vow, [a,b,c,d,e],0), -0.4,1);
      pan5=Pan2.ar(LinSelectX.ar(vow, [a,b,c,d,e],0), 0.4,1);
      pan6=Pan2.ar(LinSelectX.ar(vow, [a,b,c,d,e],0), 0.6,1);
      pan7=Pan2.ar(LinSelectX.ar(vow, [a,b,c,d,e],0), 0.8,1);
      pan8=Pan2.ar(LinSelectX.ar(vow, [a,b,c,d,e],0), 1,1);

      env = EnvGen.ar(Env.adsr(attackTime:0.5, decayTime:0.2, sustainLevel:vel, releaseTime:0.05), gate, doneAction: 2);

    	mixed_pans = Mix.new([pan1, pan2, pan3, pan4, pan5, pan6, pan7, pan8]);

      Out.ar(0, mixed_pans*vel*env)
    }).send;

    this.addCommand("noteOn", "ffii", { arg msg;
      var val = msg[1];
      var vel = msg[2];
      var vow = msg[3];
      var vow2 = msg[4];
      var note = Dictionary.new;
      note["vow1"] = Synth.new(\choir,
          [
              \fq, val,
              \gate, 1,
              \vel, vel,
              \vow, vow,
              \attack, attack,
          ]
      ); 
      note["vow2"] = Synth.new(\choir,
          [
              \fq, val,
              \gate, 0,
              \vel, vel,
              \vow, vow2,
              \attack, attack,
          ]
      ); 
      TempoClock.default.sched(delay, {
        note["vow2"].set(\gate, 1);
        nil
      });
      notes.put(val, note);
    });

    this.addCommand("noteOff", "f", { arg msg;
      var val = msg[1];
      var note = notes.at(val);
      var vow2;
      vow2 = note.at("vow2");
      note["vow1"].set(\gate, 0); 
      notes.removeAt(val);
      TempoClock.default.sched(delay, {
        vow2.set(\gate, 0);
        nil
      });
    });

    this.addCommand("amp", "f", { arg msg;
      amp = msg[1];
    });

    this.addCommand("attack", "f", { arg msg;
      attack = msg[1];
    });

    this.addCommand("delay", "f", { arg msg;
      delay = msg[1];
    });

  }
}