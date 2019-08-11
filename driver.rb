#!/usr/bin/env ruby

require 'audio-playback'
require_relative 'vail'

morse_encoder = Vail.new(25, 10)
audio_playback_options = { channels: [0, 1], latency: 1, output_device: 1 }
group_length = 3
temp_file_name = 'morse.wav'
begin
  while true do
    text = ""
    morse_encoder.clear_samples
    group_length.times do
      text << morse_encoder.get_random_character
    end
    morse_encoder.encode_text text
    morse_encoder.write_out_wavefile
    playback = AudioPlayback.play(temp_file_name, audio_playback_options)
    playback.block
    gets
    puts text
    gets
  end
rescue StandardError => e
  puts "Control-C"
ensure
  File.delete temp_file_name
end
