# frozen_string_literal: true

# class for coloring text using ansi escape codes
class Color
  attr_accessor :underlined, :default_color, :reset

  # rubocop:disable Layout/HashAlignment
  COLORS = {
    green:  2,
    red:    1,
    orange: 3,
    blue:   39,
    purple: 93,
    pink:   219,
    yellow: 226,
    black:  16,
    white:  15
  }.freeze

  # rubocop:enable Layout/HashAlignment
  def initialize(default_color = nil)
    @bg = nil
    @fg = nil
    @reset = false
    @underlined = false
    @default_color = default_color || self
  end

  def set_bg(red, green = nil, blue = nil)
    @bg = green ? { r: red, g: green, b: blue } : red
    self
  end

  def set_fg(red, green = nil, blue = nil)
    @fg = green ? { r: red, g: green, b: blue } : red
    self
  end

  def color_str(color, background: false)
    if color.is_a?(Hash)
      prefix = background ? '48;2' : '38;2'
      "#{prefix};#{color[:r]};#{color[:g]};#{color[:b]}"
    else
      prefix = background ? '48;5' : '38;5'
      "#{prefix};#{color}"
    end
  end

  def sgr_str(parameters)
    parameters.empty? ? '' : "\033[#{parameters.join(';')}m"
  end

  def to_s
    call('', reset_color: false)
  end

  def parameters
    parameters = []
    parameters.push(color_str(@fg, background: false)) if @fg
    parameters.push(color_str(@bg, background: true))  if @bg
    parameters.push('4') if @underlined
    parameters.push('0') if @reset
    parameters
  end

  def call(str = '', reset_color: true)
    reset = ''
    if reset_color
      reset = "\033[0m"
      reset += @default_color.call(reset_color: false) if @default_color
    end

    "#{sgr_str(parameters)}#{str}#{reset}"
  end
end
