# frozen_string_literal: true

require_relative './color'

# factory for colors, which reset to a default color after coloring the text
class DefaultColorFactory
  def default_color(default_color)
    @default_color = default_color
    self
  end

  def create(foreground = nil, background = nil)
    color = Color.new(@default_color)
    color.set_fg(foreground) if foreground
    color.set_bg(background) if background
  end
end
