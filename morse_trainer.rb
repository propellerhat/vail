class MorseTrainer
  require_relative 'encoder'
  require_relative 'callsign_generator'

  attr_accessor :prng
  attr_accessor :encoder

  def initialize(trainer_options, encoder_options)
    @encoder = Encoder.new(encoder_options)
    @prng = Random.new

    # These should change when in "learning characters" mode. For now,
    # that's not implemented.
    @alphabet = "abcdefghijklmnopqrstuvwxyz"
    @digits = "0123456789"
    @punctuation = ".,?/&!()"
    @prosigns = [].push("")

    @trainer_options = trainer_options
    @training_mode = @trainer_options[:mode]

    if @training_mode == :wordsworth
      @wordsworth_words = []
      File.open(@trainer_options[:filename], 'r').each_line do |line|
        @wordsworth_words << line.chomp
      end
    end
  end

  def get_random_letter
    @alphabet[@prng.rand(@alphabet.length)]
  end

  def get_random_digit
    @digits[@prng.rand(@digits.length)]
  end

  def get_random_alnum
    choices = @alphabet + @digits
    choices[@prng.rand(choices.length)]
  end

  def get_random_punctuation
    @punctuation[@prng.rand(@punctuation.length)]
  end

  def get_tricky_dit_character
    chars = "eish5"
    chars[@prng.rand(chars.length)]
  end

  def get_tricky_dit_dah_character
    chars = "auv4"
    chars[@prng.rand(chars.length)]
  end

  def get_tricky_dah_dit_character
    chars = "ndb6"
    chars[@prng.rand(chars.length)]
  end

  def generate_message
    message = ""
    @encoder.clear_samples

    case @training_mode
    when :callsigns
      message = CallsignGenerator.get_random

    when :groups
      @trainer_options[:group_size].times do
        message << get_random_letter
      end

    when :tricky_sequences
      sequences = [:dits, :dah_dit, :dit_dah, :fl]
      current_sequence = sequences[@prng.rand(sequences.length)]

      case current_sequence
      when :dits
        @trainer_options[:group_size].times do
          message << get_tricky_dit_character
        end

      when :dah_dit
        @trainer_options[:group_size].times do
          message << get_tricky_dah_dit_character
        end

      when :dit_dah
        @trainer_options[:group_size].times do
          message << get_tricky_dit_character
        end

      when :fl
        @trainer_options[:group_size].times do
          message << "fl"[@prng.rand(2)]
        end

      end

    when :wordsworth
      message = @wordsworth_words[@prng.rand(@wordsworth_words.length)]

    else
      $stderr.write "Unknown training mode."
    end

    @encoder.encode_text message
    @encoder.write_out_wavefile @trainer_options[:wave_filename]
    message
  end

end
