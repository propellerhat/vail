class CallsignGenerator
  def self.get_random(zone = :us)
    prng = Random.new
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
      callsign << ("A".."Z").to_a[prng.rand(26)]
    end

    callsign
  end
end
