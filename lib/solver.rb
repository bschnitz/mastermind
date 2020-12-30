# frozen_string_literal: true

require_relative './board'
require_relative './board_printer'

# Algorithm for artificially solving Mastermind games
class Solver
  def initialize(board)
    if board.number_of_pegs != 4 || board.colors.length != 6
      raise ArgumentError 'Solver works only with four pegs '\
        'and six possible colors at the moment.'
    end

    @board = board
    @guesses = []
    @possibilities = []
    @guessed_colors = []
    @possible_colors = board.colors
  end

  def solve
    until @board.no_more_guesses? || @board.guessed_correctly
      make_guess
      evaluate_guess
    end
  end

  def key_pegs
    key_peg_colors = @board.key_peg_colors(@board.current_row - 1)
    key_peg_colors.each_with_object(Hash.new(0)) do |color, colors|
      colors[color] += 1
    end
  end

  def evaluate_guess
    guess = @guesses[-1]
    k_pegs = key_pegs

    possibilities =
      if k_pegs[:red].zero?
        evaluate_white_key_pegs([], guess, k_pegs[:white])
      elsif k_pegs[:white].zero?
        red_position_groups = draw_k([*(0...guess.length)], k_pegs[:red])
        evaluate_red_key_pegs(red_position_groups, guess)
      else
        red_position_groups = draw_k([*(0...guess.length)], k_pegs[:red])
        evaluate_white_key_pegs_after_red(red_position_groups)
      end

    add_other_colors!(possibilities)

    merge_possibilities(possibilities)
  end

  def filter_possibile_colors!(possibilities)
    possibilities.map! do |possibility|
      possibility.map! do |colors|
        colors.filter { |color| @possible_colors.include?(color) }
      end
      possibility.filter { |el| !el.empty? }
    end
    possibilities.filter! { |possibility| possibility.length == 4 }
  end

  def merge_possibilities(possibilities)
    if possibilities.empty?
      @possible_colors -= @guesses[-1]
      filter_possibile_colors!(@possibilities)
      return
    end

    if @possibilities.empty?
      @possibilities = possibilities
      return
    end

    @possibilities = @possibilities.each_with_object([]) do |poss1, merged|
      possibilities.each do |poss2|
        new_possibilities = merge_possibility_pair(poss1, poss2)
        merged.push(new_possibilities) if new_possibilities
      end
    end
  end

  def merge_possibility_pair(possibility1, possibility2)
    possibility1.map.with_index do |colors, index|
      common_colors = colors & possibility2[index]
      return nil if common_colors.empty?

      common_colors
    end
  end

  def evaluate_white_key_pegs_after_red(red_position_groups)
    guess = @guesses[-1]
    red_position_groups.each_with_object([]) do |positions, possibilities|
      white_ps = evaluate_white_key_pegs(positions, guess, key_pegs[:white])
      white_ps.map do |w_possibility|
        positions.each { |pos| w_possibility[pos] = guess[pos] }
        possibilities.push(w_possibility)
      end
    end
  end

  def evaluate_red_key_pegs(red_position_groups, guess)
    red_position_groups.map do |group|
      group.each_with_object(Array.new(4, nil)) do |position, possibility|
        possibility[position] = guess[position]
      end
    end
  end

  def add_other_colors!(possibilities)
    current_colors = @guesses[-1].uniq
    other_colors = @possible_colors - current_colors
    possibilities.each do |pos|
      colors = pos.filter { |el| el }
      pos.map!.with_index do |el, i|
        if el
          [el]
        else
          other_colors + colors - [@guesses[-1][i]]
        end
      end
    end
  end

  def evaluate_white_key_pegs(occupied_positions, guess, num_white_pegs)
    other_positions = [*(0...@board.number_of_pegs)] - occupied_positions

    # get num_white_pegs other colors and build possible solutions from them
    position_groups = draw_k(other_positions, num_white_pegs)

    # possible solutions are all permutations, where no code peg is on the
    # place, where it was set in the guess
    mappings = position_groups.reduce([]) do |mappings, positions|
      mappings.push(*identity_free_bijections(positions, other_positions))
    end

    positions = mappings.each_with_object([]) do |mapping, positions|
      next if mapping.any? { |(from, to)| guess[from] == guess[to] }

      position = mapping.each_with_object(Array.new(4, nil)) do |(from, to), white_possibility|
        white_possibility[to] = guess[from]
      end

      positions.push(position)
    end

    positions.reject(&:empty?).uniq
  end

  def dissolve(possibility)
    possibility.reduce([[]]) do |dissolved_possibilities, colors|
      colors.each_with_object([]) do |color, dissolved|
        dissolved_possibilities.each do |dissolved_possibility|
          dissolved.push(dissolved_possibility + [color])
        end
      end
    end
  end

  def get_possibility_with_max_color_multiplicity(possibility)
    dissolved_possibilities = dissolve(possibility)
    dissolved_possibilities.reduce(dissolved_possibilities.first) do |min, dissolved|
      dissolved.uniq.length < min.uniq.length ? dissolved : min
    end
  end

  def sort_possibilities_by_color_multiplicity!(possibilities)
    possibilities.sort_by! do |possibility|
      get_possibility_with_max_color_multiplicity(possibility).length
    end
  end

  def possibilities_each(possibilities, object = nil)
    possibilities.each do |possibility|
      dissolve(possibility).each do |dissolved|
        object ? yield(dissolved, object) : yield(dissolved)
      end
    end
    object
  end

  def subtract_possibility(possibilities, possibility)
    possibilities.each_with_object([]) do |ps, pss|
      dissolved = dissolve(ps)
      if dissolved.include?(possibility)
        filtered_p = dissolve(ps)
                     .filter { |p| p != possibility }
                     .map { |p| p.map { |color| [color] } }
        pss.push(*filtered_p)
      else
        pss.push(ps)
        exit
      end
    end
  end

  def next_guess
    colors = @board.colors

    if @possibilities.empty?
      i = @guesses.length
      return [colors[i * 2]] * 2 + [colors[i * 2 + 1]] * 2
    end

    possibilities = @possibilities
    loop do
      guess = Array.new(@board.number_of_pegs, [nil, 0])
      (0...@board.number_of_pegs).each do |i|
        counter = Hash.new(0)
        possibilities_each(possibilities) do |possibility|
          zipped = guess.zip(possibility)
          next if zipped.any? { |el| el[0][0] && el[0][0] != el[1] }

          counter[possibility[i]] += 1
        end
        guess[i] = (counter.max_by { |_, v| v })
      end
      guess.map! { |(color, _)| color }
      return guess unless @guesses.include?(guess)

      possibilities = subtract_possibility(possibilities, guess)
    end
  end

  def make_guess
    @guesses.push(next_guess)
    @board.guess(@guesses[-1])
  end
end
