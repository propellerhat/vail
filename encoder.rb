class Encoder

  require 'wavefile'

  SAMPLE_RATE = 44100
  
  attr_accessor :character_wpm
  attr_accessor :freq, :samples, :cursor_step
  attr_accessor :samples_per_dit, :seconds_per_dit
  attr_accessor :char_map

  def initialize(character_wpm: 25, farnsworth_spacing: 0, freq: 600.0)
    @character_wpm = character_wpm
    @farnsworth_spacing = farnsworth_spacing
    @freq = freq

    @seconds_per_dit = 60.0 / (@character_wpm * 50)
    @samples_per_dit = (SAMPLE_RATE * @seconds_per_dit).round
    
    if farnsworth_spacing.zero?
      @farnsworth_samples_per_dit = 0
    else
      farnsworth_seconds_per_dit = 60.0 / (farnsworth_spacing * 50)
      @farnsworth_samples_per_dit = (SAMPLE_RATE *
                                     farnsworth_seconds_per_dit).round
    end

    @cursor_step = @freq / SAMPLE_RATE
    @samples = []

    @char_map = {}
    @char_map['a'] = '.-'
    @char_map['b'] = '-...'
    @char_map['c'] = '-.-.'
    @char_map['d'] = '-..'
    @char_map['e'] = '.'
    @char_map['f'] = '..-.'
    @char_map['g'] = '--.'
    @char_map['h'] = '....'
    @char_map['i'] = '..'
    @char_map['j'] = '.---'
    @char_map['k'] = '-.-'
    @char_map['l'] = '.-..'
    @char_map['m'] = '--'
    @char_map['n'] = '-.'
    @char_map['o'] = '---'
    @char_map['p'] = '.--.'
    @char_map['q'] = '--.-'
    @char_map['r'] = '.-.'
    @char_map['s'] = '...'
    @char_map['t'] = '-'
    @char_map['u'] = '..-'
    @char_map['v'] = '...-'
    @char_map['w'] = '.--'
    @char_map['x'] = '-..-'
    @char_map['y'] = '-.--'
    @char_map['z'] = '--..'
    @char_map['0'] = '-----'
    @char_map['1'] = '.----'
    @char_map['2'] = '..---'
    @char_map['3'] = '...--'
    @char_map['4'] = '....-'
    @char_map['5'] = '.....'
    @char_map['6'] = '-....'
    @char_map['7'] = '--...'
    @char_map['8'] = '---..'
    @char_map['9'] = '----.'
    @char_map['.'] = '.-.-.-'
    @char_map[','] = '--..--'
    @char_map['?'] = '..--..'
    @char_map['/'] = '-..-.'
    @char_map["'"] = '.----.'
    @char_map['!'] = '-.-.--'
    @char_map['('] = '-.--.'
    @char_map[')'] = '-.--.-'
    @char_map['&'] = '.-...'
    @char_map[':'] = '---...'
    @char_map[';'] = '-.-.-.'
    @char_map['='] = '-...-'
    @char_map['+'] = '.-.-.-'
    @char_map['-'] = '-....-'
    @char_map['_'] = '..--.-'
    @char_map['"'] = '.-..-.'
    @char_map['$'] = '...-..-'
    @char_map['@'] = '.--.-.'
    
    @prosign_map = {}
    @prosign_map['<AA>'] = ['.-.-', 'New Line']
    @prosign_map['<AR>'] = ['.-.-.', 'New Page', 'Same as +']
    @prosign_map['<AS>'] = ['.-...', 'Wait']
    @prosign_map['<BT>'] = ['-...-', 'New Paragraph']
    @prosign_map['<CT>'] = ['-.-.-', 'Attention']
    @prosign_map['<HH>'] = ['........', 'Error']
    @prosign_map['<KN>'] = ['-.--.', 'Invitation for named station to transmit']
    @prosign_map['<NJ>'] = ['-..---', 'Shift to Wabun code']
    @prosign_map['<SK>'] = ['...-.-', 'End of contact', 'Sometimes <VA>']
    @prosign_map['<SN>'] = ['...-.', 'Understood']
    @prosign_map['<SOS>'] = ['...---...', 'International distress signal']
    @prosign_map['<BK>'] = ['-...-.-', 'Break', 'Supposed to be an acronym, but sent as prosign on occasion']
    @prosign_map['<CL>'] = ['-.-..-..', 'Closing', 'Supposed to be an acronym, but sent as prosign on occasion']

  end

  def generate_char(char)
    elements = @char_map[char]
    elements.each_char do |element|
      samples = @samples_per_dit
      samples *= 3 if element == '-'
      generate_tone samples
      generate_silence @samples_per_dit
    end

    # The character elements have been created. Now,
    # we need to make sure that a minimum amout of space occurs
    # after the character. Since we always add one dit length
    # of silence after each character element, we need only add
    # 2 more to get the regulation 3.
    generate_silence (@samples_per_dit * 2)

    if @farnsworth_spacing.positive?
      # We also need to add the farnsworth adjustment to the silence.
      # First, figure out the farnsworth inter-character space:
      farnsworth_additional_silence =  @farnsworth_samples_per_dit * 3
      # Then, subtract the existing silence
      farnsworth_additional_silence -= @samples_per_dit * 3
      generate_silence farnsworth_additional_silence
    end

  end

  def generate_silence(num_samples)
    @samples += [].fill(0.0, 0, num_samples)
  end

  def generate_tone(num_samples)
    cursor = 0.0
    num_samples.times do
      @samples << Math::sin(cursor * Math::PI * 2)
      cursor += @cursor_step
    end

    # Now smooth the tone.
    ramp_delta = 0.007
    
    # Smooth the start of the tone.
    ramp_value = 0.0
    index = @samples.length - num_samples
    until ramp_value > 1.0 do
      @samples[index] *= ramp_value
      ramp_value += ramp_delta
      index += 1
    end

    # Smooth the end of the tone.
    ramp_value = 0.0
    index = -1
    until ramp_value > 1.0 do
      @samples[index] *= ramp_value
      ramp_value += ramp_delta
      index -= 1
    end
  end

  def clear_samples
    @samples = []
  end

  def encode_text(text)
    text.downcase.each_char do |c|
      if ' ' == c
        # The way in which characters are encoded, there will already
        # be 3 dits of silence on the end of the character. We need only
        # add 4 more to get the regulation 7 dits to separate words.
        if farnsworth_spacing.positive?
          generate_silence(@farnsworth_samples_per_dit * 4)
        else
          generate_silence(@samples_per_dit * 4)
        end
      elsif '<' == c
        # This is the start of a prosign. We must consume and encode the
        # prosign.
        # XXX: Will implement later
      else
        generate_char c
      end
    end
  end

  def write_out_wavefile(wave_filename)
    buffer_format = WaveFile::Format.new(:mono, :float, SAMPLE_RATE)
    buffer = WaveFile::Buffer.new(@samples, buffer_format)
    
    file_format = WaveFile::Format.new(:mono, :pcm_16, SAMPLE_RATE)
    WaveFile::Writer.new(wave_filename, file_format) do |writer|
      writer.write(buffer)
    end
  end

end
