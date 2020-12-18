# frozen_string_literal: true

require_relative './color'
require_relative './default_color_factory'

# prints the Mastermind board to terminal
class BoardPrinter
  def initialize(board)
    @board = board
    @peg_symbols     = { empty: '◯', set: '⬤' }
    @key_peg_symbols = { empty: '⯎', set: '⯌' }
    create_colors
    @peg_separator = '  '
    @row_separator_length = calculate_row_separator_length
    @key_row_separator = ' ' * (@board.number_of_pegs * 2 + 1)
  end

  def calculate_row_separator_length
    # length of peg_symbol == 1
    # one additional space at both boarders of each row: "| #{pegs} |"
    (1 + @peg_separator.length) * (@board.number_of_pegs - 1) + 3
  end

  def create_colors
    fg = Color::COLORS[:white]
    bg = Color::COLORS[:black]

    @default_color = Color.new.set_fg(fg).set_bg(bg)

    cf = DefaultColorFactory.new.default_color(@default_color)

    @colors = Color::COLORS.transform_values { |color| cf.create(color, bg) }
    @colors[:default] = @default_color
  end

  def pegs_for_print(colors, symbols)
    colors.map do |peg_color|
      if peg_color == :none
        @default_color.call(symbols[:empty])
      else
        @colors[peg_color].call(symbols[:set])
      end
    end
  end

  def row_for_print(row)
    code_pegs = pegs_for_print(row[:code_peg_colors], @peg_symbols).join('  ')
    key_pegs = pegs_for_print(row[:key_peg_colors], @key_peg_symbols).join(' ')

    " ┃ #{code_pegs} ┃ #{key_pegs} "
  end

  def row_separator(separator_char)
    separator_char * @row_separator_length
  end

  def print
    rows_for_print = @board.rows.each.reduce([]) do |rows, row|
      rows.push(row_for_print(row))
    end.join("\n ┃#{row_separator(' ')}┃#{@key_row_separator}\n")

    puts @default_color
    puts "#{@default_color} ┏#{row_separator('━')}┓#{@key_row_separator}"
    puts rows_for_print
    puts " ┗#{row_separator('━')}┛#{@key_row_separator}"
  end
end
