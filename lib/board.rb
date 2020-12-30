# frozen_string_literal: true

require_relative './color'
require_relative './helpers'

# The board represents the state of the Mastermind game
class Board
  attr_reader :rows, :number_of_pegs, :guessed_correctly, :current_row, :colors
  attr_accessor :code

  def initialize(colors, number_of_pegs)
    @number_of_pegs = number_of_pegs
    @number_of_rows = 12

    @colors = colors
  end

  def reset
    @current_row = 0

    @guessed_correctly = false

    initialize_rows
    set_random_code
  end

  def initialize_rows
    @rows = Array.new(@number_of_rows) do
      { code_peg_colors: Array.new(@number_of_pegs, :none),
        key_peg_colors: Array.new(@number_of_pegs, :none) }
    end
  end

  def set_random_code
    @code = (1..@number_of_pegs).map do
      @colors[rand(@colors.length)]
    end
  end

  def guess(colors)
    if colors.length != @number_of_pegs
      raise(ArgumentError, 'Wrong number of colors provided. ' \
                           "Need #{@number_of_pegs} colors.")
    end

    @rows[@current_row][:code_peg_colors] = colors
    @rows[@current_row][:key_peg_colors] = get_key_peg_colors(colors)

    @guessed_correctly = @rows[@current_row][:key_peg_colors].all? do |color|
      color == :red
    end

    @current_row += 1
  end

  def current_row_colors
    @rows[@current_row][:code_peg_colors]
  end

  def no_more_guesses?
    @current_row >= @number_of_rows
  end

  def key_peg_colors(row = nil)
    @rows[row || @current_row][:key_peg_colors]
  end

  def get_key_peg_colors(guessed_colors)
    correct_guesses, other_pegs = @code.partition.with_index do |color, i|
      guessed_colors[i] == color
    end

    other_guesses = subtract_with_multiplicity(guessed_colors, correct_guesses)
    at_wrong_position = intersect_with_multiplicity(other_guesses, other_pegs)

    key_peg_colors_by_count(correct_guesses.length, at_wrong_position.length)
  end

  def key_peg_colors_by_count(count_correct, count_wrong_position)
    count_rest = @number_of_pegs - (count_correct + count_wrong_position)
    [:red] * count_correct +
      [:white] * count_wrong_position +
      [:none] * count_rest
  end
end
