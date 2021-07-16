#!/usr/bin/env ruby
require_relative 'morse_trainer'
require 'audio-playback'
require 'pp'

encoder_options = { character_wpm: 25,
                    farnsworth_spacing: 10,
                    freq: 600.0 }

trainer_options = { mode: :groups,
                    filename: 'wordsworth_words.txt',
                    group_size: 3,
                    wave_filename: 'morse.wav' }

audio_playback_options = { channels: [0, 1], latency: 1, output_device: 1 }

puts "Here are the encoder options:"
pp encoder_options
puts "Would you like to change? [Y/n]"
if $stdin.gets.strip.upcase == "Y"
  puts "WPM [#{encoder_options[:character_wpm]}]"
  response = $stdin.gets.strip
  encoder_options[:character_wpm] = response.to_i unless response.empty?
  puts "Farnsworth [#{encoder_options[:farnsworth_spacing]}]"
  response = $stdin.gets.strip
  encoder_options[:farnsworth_spacing] = response.to_i unless response.empty?
  puts "Frequency [#{encoder_options[:freq]}]"
  response = $stdin.gets.strip
  encoder_options[:freq] = response.to_f unless response.empty?
end

puts "Choose training mode:"
puts " 1 - Callsigns"
puts " 2 - Groups"
puts " 3 - Tricky Sequences"
puts " 4 - Wordsworth"
ans = $stdin.gets.strip.to_i
case ans
when 1
  trainer_options[:mode] = :callsigns
when 2
  trainer_options[:mode] = :groups
  puts "Group size?"
  trainer_options[:group_size] = $stdin.gets.strip.to_i
when 3
  trainer_options[:mode] = :tricky_sequences
  puts "Group size?"
  trainer_options[:group_size] = $stdin.gets.strip.to_i
when 4
  trainer_options[:mode] = :wordsworth
  puts "Filename?"
  trainer_options[:filename] = $stdin.gets.strip
end

trainer = MorseTrainer.new(trainer_options, encoder_options)

begin
  
  while true do
    message = trainer.generate_message
    playback = AudioPlayback.play(trainer_options[:wave_filename],
                                  audio_playback_options)
    playback.block
    $stdin.gets.strip
    puts message
    $stdin.gets.strip
  end

rescue StandardError => e
  $stderr.write e.backtrace.join("\n")

ensure
  File.delete trainer_options[:wave_filename]

end

