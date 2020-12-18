# frozen_string_literal: true

require_relative './lib/board_printer'
require_relative './lib/board'
require_relative './lib/color'

# controls the game (board, user interaction, ai)
class Mastermind
  def initialize
    @colors = %i[blue orange pink yellow red green].sort
    @colors_str = @colors.map(&:to_s)
    @minimum_unique_color_start_lengths =
      minimum_unique_start_lengths(@colors_str)
    @board = Board.new(@colors, 4)
    @board_printer = BoardPrinter.new(@board)

    initialize_formatters

    @color_choice_str = color_choice_str
  end

  def initialize_formatters
    @reset = Color.new
    @reset.reset = true
    @underlined = Color.new
    @underlined.default_color = nil
    @underlined.underlined = true
  end

  def game_loop
    until no_more_guesses? || guessed_correctly?
      @board_printer.print
      return unless (guessed_colors = user_input_loop)

      @board.guess(guessed_colors)
    end
  end

  def guessed_correctly?
    if @board.guessed_correctly
      @board_printer.print
      print @reset
      puts "\nYou guessed correctly in #{@board.current_row} turns."
      puts 'You won.'
    end
    @board.guessed_correctly
  end

  def no_more_guesses?
    if @board.no_more_guesses?
      @board_printer.print
      puts @reset
      puts 'No more guesses left, You lost.'
    end
    @board.no_more_guesses?
  end

  def user_input_loop
    print @reset
    loop do
      puts "\nGuess #{@board.number_of_pegs} colors."\
        ' Input them seperated by spaces.'
      puts "Possible choices: #{@color_choice_str}\n'q' for Quit"

      return nil unless (choices = chosen_colors_from_user_input)
      return choices if choices.length == @board.number_of_pegs

      puts "Wrong input, got: #{choices}"
    end
  end

  def chosen_colors_from_user_input
    input = gets.chomp
    return nil if input.downcase == 'q'

    choices = input.split(/\s+/).map do |choice|
      @colors_str.bsearch { |x| x.match?(/^#{choice}/) ? 0 : choice <=> x }
    end
    choices.filter { |el| el }.map(&:to_sym)
  end

  def color_choice_str
    @colors.map do |color|
      underline_length = @minimum_unique_color_start_lengths[color.to_s]
      underline_length = 0 if color.length == underline_length
      head = color[0...underline_length]
      tail = color[underline_length...color.length]
      "#{@underlined.call(head)}#{tail}"
    end.join(' ')
  end
end

Mastermind.new.game_loop
