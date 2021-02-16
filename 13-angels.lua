-- 13 angels
-- v1.0 @dzautner
--
-- delay vowel synth 
--
-- k2 - change vowel
-- k3 - change delayed vowel
-- all encodres change the delay time between the two vowels 

local MIDIHelpers = include("lib/midi_helpers")
local Helpers = include("lib/helpers")

engine.name = 'Choir'

-- vowels map
local vowels = { "a", "eh", "ih", "oh", "uh", "rand" }
local RANDOM_VOW = 6;

--synth params
local attack = 2;
local delay = 0.3;
local vow1 = RANDOM_VOW;
local vow2 = RANDOM_VOW;

function init()
  -- Listen to a specific MIDI channel, or 0 (default) for all of them.
  params:add_number('midi_ch', "MIDI ch", 0, 16, 0)

  MIDIHelpers.connect(on_midi_event)
  screen.line_width(0)
  screen.font_face(2)
  screen.font_size(8)
  redraw()
end

function on_midi_event(data)
  msg = midi.to_msg(data)
  -- filter out non-note events
  if msg.type == "note_on" or msg.type == "note_off" then
    if msg.ch == params:get('midi_ch') or params:get('midi_ch') == 0 then
      play(msg)
    end
  end
end

local notes_playing = {}
local MAX_NOTES = 2
function play(msg)
  hz = MIDIHelpers.note_to_hz(msg.note)
  if msg.type == 'note_on' then
    if Helpers.table_length(notes_playing) >= MAX_NOTES then
      return
    end
    if notes_playing[hz] ~= null then
      return
    end
    notes_playing[hz] = true
    local v1;
    local v2;
    if vow1 == RANDOM_VOW then v1 = math.random(0,4) else v1 = vow1 - 1 end
    if vow2 == RANDOM_VOW then v2 = math.random(0,4) else v2 = vow2 - 1 end
    engine.noteOn(hz, msg.vel/127, v1, v2)
    animatevowels(vowels[v1+1], vowels[v2+1], delay)
  elseif msg.type == 'note_off' then
    if notes_playing[hz] == null then
      return
    end
    engine.noteOff(hz)
    notes_playing[hz] = null
  end
end

------ Controls

function enc(id,delta)
  delay = Helpers.clamp(delay + delta/10, 0, 10)
  engine.delay(delay)
end


function key(id,state)
  if id == 2 and state == 1 then
    if vow1 == RANDOM_VOW then vow1 = 0 end
    vow1 = vow1 + 1
  end
  if id == 3 and state == 1 then
    if vow2 == RANDOM_VOW then vow2 = 0 end
    vow2 = vow2 + 1
  end
end


------ UI
local viewport = { width = 128, height = 64 }
local frames_per_second = 10
local frame = 0
   
local _vowels_to_animate = {}
function animatevowels(vow1, vow2, delay)
  unique_id = math.random()
  unique_id2 = math.random()
  _vowels_to_animate[unique_id] = {
    label = vow1,
    start_in_frame = 0,
    current = { x = 14, y = 26, b = 15 },
    step_function = function (x, y, b) 
        return {
          x = x+1,
          y = y-(0.5),
          b = b-(1/2)
        }
    end
  }
  
  frame_delay = (frames_per_second * delay)
  _vowels_to_animate[unique_id2] = {
    label = vow2,
    start_in_frame = frame + frame_delay,
    current = { x = 106, y = 26, b = 15 },
    step_function = function (x, y, b)
        return {
          x = x-1,
          y = y-0.5,
          b = b-(1/2)
        }
    end
  }
end

function vowel_animation_did_end(c)
  return c['x'] > 128 or c['y'] > 64 or c['x'] < 0  or c['y'] < 0 or c['b'] < 0
end

vowels_played = ""
function draw_animated_vowels() 
  for id, vowel in pairs(_vowels_to_animate) do
    if vowel['_initiated'] == nil then
      if frame >= vowel['start_in_frame'] then
        if string.len(vowels_played) > 370 then
          vowels_played = string.sub(vowels_played, 4)
        end
        vowels_played = vowels_played .. " " .. vowel['label']
        screen.level(vowel['current']['b'])
        screen.move(vowel['current']['x'], vowel['current']['y'])
        screen.text(vowel['label'])
        screen.level(15)
        _vowels_to_animate[id]['_initiated'] = true
      end
    else
      _vowels_to_animate[id].current = _vowels_to_animate[id].step_function(
        vowel['current']['x'],
        vowel['current']['y'],
        vowel['current']['b']
      )
      screen.level(math.floor(vowel['current']['b']))
      screen.move(vowel['current']['x'], vowel['current']['y'])
      screen.text(vowel['label'])
      screen.level(15)
      if vowel_animation_did_end(vowel['current']) then
        _vowels_to_animate[id] = nil
      end
    end
  end
end

local angels_frames = 8
local left_angel_frame = 1
local right_angel_frame = 5
function draw_angels()
  screen.display_png(_path.this.path.."art/standby_"..left_angel_frame..".png", 0, 0)
  screen.display_png(_path.this.path.."art/right_standby_"..right_angel_frame..".png", 0, 0)
  if left_angel_frame == angels_frames then
    left_angel_frame = 1
  else
    left_angel_frame = left_angel_frame + 1
  end
  if right_angel_frame == angels_frames then
    right_angel_frame = 1
  else
    right_angel_frame = right_angel_frame + 1
  end
end

function draw_played_vowels()
  screen.level(1)
  screen.move(0, 8)
  for i,v in ipairs(Helpers.splitByChunk(vowels_played, 45)) do
    screen.text(v)
    screen.move(0, (i+1)*8)
  end
  screen.level(15)

end
function redraw()
  screen.clear()
  draw_played_vowels()
  draw_angels()
  draw_ui()
  draw_animated_vowels()
  screen.update()
end

function draw_ui()
  screen.level(15)
  screen.move(52, 10)
  screen.text('dly: '..delay)
  
  screen.move(35,viewport.height-5)
  screen.text(vowels[vow1])

  screen.move(80,viewport.height-5)
  screen.text(vowels[vow2])
end

-- time thingies
re = metro.init()

re.time = 1.0/frames_per_second

re.event = function()
  frame = frame + 1
  redraw()
end

re:start()