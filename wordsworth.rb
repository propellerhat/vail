#!/usr/bin/env ruby
require 'audio-playback'
require_relative 'vail'

morse_encoder = Vail.new(25, 10)
audio_playback_options = { channels: [0, 1], latency: 1, output_device: 1 }
temp_file_name = 'morse.wav'
words = []
File.open('words.txt', 'r').each_line do |line|
  words << line.chomp
end
prng = Random.new
begin
  while true do
    morse_encoder.clear_samples
    current_word = words[prng.rand(words.size)]
    morse_encoder.encode_text current_word
    morse_encoder.write_out_wavefile
    playback = AudioPlayback.play(temp_file_name, audio_playback_options)
    playback.block
    gets
    puts current_word
    gets
  end
rescue StandardError => e
  puts "Control-C"
ensure
  File.delete temp_file_name
end
