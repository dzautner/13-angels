local MIDIHelpers = {}

function MIDIHelpers.connect(cb)
  midi_device = {} -- container for connected midi devices
  for i = 1,#midi.vports do -- query all ports
      midi_device[i] = midi.connect(i) -- connect each device
      midi_device[i].event = cb
  end
end
  
function MIDIHelpers.note_to_hz(note)
  return (440 / 32) * (2 ^ ((note - 9) / 12))
end


return MIDIHelpers