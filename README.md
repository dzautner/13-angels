# 13 angels

sighing angel-voice synth for the **[Monome Norns](https://monome.org/docs/norns/)** and plain SuperCollider, recreating the voices of **[13 Angels Standing Guard 'Round The Side Of Your Bed](https://www.youtube.com/watch?v=9fN7udMAMog)** by A Silver Mt. Zion.

Heavily based on [Matias Monteagudo's work](https://patchstorage.com/mm-vowels-synth/).

![13-angels](13-angels.gif)

## listen

Everything below is synthesized; no audio from the record is used.

* **[samples/intro.mp3](samples/intro.mp3)**: the song's intro, re-sung by the synth (1:25)
* **[samples/symphony.mp3](samples/symphony.mp3)**: *"Thirteen Angels"*, a symphony for one voice (5:31), all four movements sung by this synth:
  * **I. Standing Guard** (0:00): the intro grows into a full choir
  * **II. Whispers** (1:33): breathy vowel arpeggios in canon
  * **III. Lament** (2:25): a chorale, then a soprano solo over it
  * **IV. Ascension** (3:55): an accelerando, up a tone, a major climax, and the voices sighing away one by one

## the sound

The voice was rebuilt from measurements of the song's intro (0:00–1:20), then tuned by an optimizer that renders it offline and scores it against the record.

* **the music**: a steady pulse, one chord every **2.57 s**, cycling 8 chords over a pedal note at ~283.7 Hz:
  `[-2 0 2] [0 3] [0 5 8] [0 3 7] [0 7] [0 5 10] [0 3 7] [0 5 8]`
* **the vowel** is the heart of it, an **"Ah… u"**. Each note opens on a wide "ah" (first formant around 850–900 Hz), then the formant glides down through "o" and lands on "u".
* **the sigh**: on release every voice slides down and lands. The higher the voice, the earlier it lets go (about 70 ms per semitone), but all the voices land together and then stop cleanly, like running out of breath. It darkens and wobbles a little as it falls.
* **the room**: the record is essentially **mono** here. The voice uses a gated reverb wash that blooms while the voices sing and closes as they stop, so the end of each sigh stays clean.
* **one voice per part**: no vibrato to speak of, slow pitch wander, breath shaped by the same formants as the voice, and a low rumble that comes and goes with each note.

## how to use (norns)

* k2: change vowel (`angel` is the one from the record; also a, eh, ih, oh, uh, rand)
* k3: change the vowel each note morphs into
* encoders: the morph time between the two vowels
* let go of a note to make it sigh; for the record's sound, release the top note of a chord first
* params: sigh depth, sigh time, breath, room, MIDI channel

The engine (`lib/Engine_Choir.sc`) is generated from `sc/angel.scd` by `tools/build_engine.py`, so both always use the same voice. It's tested on desktop SuperCollider but not yet on norns hardware. If 4 notes are too heavy for the CPU, lower `MAX_NOTES` in `13-angels.lua`.

## desktop SuperCollider

* `sc/angel.scd`: the voice (SynthDefs and tuned defaults)
* `sc/intro.scd`: the intro, transcribed, with the record's release timing
* `sc/play.scd`: open it in the SC IDE to boot, loop the intro, or play from a MIDI keyboard
* `sc/symphony.scd`: the symphony; `sclang sc/symphony.scd out.wav`
* `sc/demo.scd`: a short tour of the other vowels, rising sighs and whisper canons
* `sclang sc/render.scd out.wav [params.json] [cycles]`: render the intro offline

## how it was tuned (analysis/)

The scripts in `analysis/` compare a render against the original intro. They expect it at `ref/orig.wav`, which is not included; grab it yourself, e.g. with `yt-dlp -x --audio-format wav`.

* `avgevent.py`: event-averaged mel spectrogram, original vs synth, plus their difference
* `formants.py`: the vowel trajectory through each note (LPC envelope)
* `decay.py`, `falls.py`: the sigh, up close (pitch, level, brightness every 50 ms; when each voice lets go)
* `micro.py`, `texture.py`: pitch wander, shimmer, stereo image, harmonic-to-noise ratio
* `optimize.py`: CMA-ES over ~60 parameters, scoring all of the above together
* `bake.py`: writes the tuned parameters (`analysis/voice.json`) back into the SuperCollider defaults
