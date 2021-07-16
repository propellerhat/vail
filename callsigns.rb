#!/usr/bin/env ruby

require 'audio-playback'
require_relative 'vail'

morse_encoder = Vail.new(25, 10)
audio_playback_options = { channels: [0, 1], latency: 1, output_device: 1 }
temp_file_name = 'morse.wav'
prng = Random.new

begin
  while true do
    morse_encoder.clear_samples

    callsign = ""
    callsign << ["A", "K", "N", "W"][prng.rand(4)]

    add_second_prefix_letter = prng.rand(2) == 0
    if callsign.start_with? "A" # We have no choice. Must add second prefix.
      callsign << ("A".."L").to_a[prng.rand(12)]
      add_second_prefix_letter = false
    end

    if add_second_prefix_letter
      callsign << ("A".."Z").to_a[prng.rand(26)]
    end
    callsign << prng.rand(10).to_s
    if callsign.start_with? "A"
      suffix_length = prng.rand(1..2) 
    else
      suffix_length = prng.rand(1..3)
    end
    suffix_length.times do
      callsign << morse_encoder.get_random_character
    end
    
    morse_encoder.encode_text callsign
    morse_encoder.write_out_wavefile
    playback = AudioPlayback.play(temp_file_name, audio_playback_options)
    playback.block
    gets
    puts callsign.upcase
    gets
  end
rescue StandardError => e
  puts "Control-C"
ensure
  File.delete temp_file_name
end
