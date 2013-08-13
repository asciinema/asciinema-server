class Terminal

  def initialize(width, height)
    @screen = TSM::Screen.new(width, height)
    @vte = TSM::Vte.new(@screen)
  end

  def feed(data)
    vte.input(data)
  end

  def snapshot
    lines = []
    last_y = nil
    line = nil

    cur_text, cur_attr = nil

    screen.draw do |x, y, char, attr|
      line = lines[y]

      unless line
        lines[y] = line = []
        cur_text = nil
      end

      if cur_text && attr == cur_attr
        cur_text << char
      else
        cur_text, cur_attr = char, attr
        line << [cur_text, cur_attr]
      end
    end

    lines
  end

  def release
    screen.release
    vte.release
  end

  private

  attr_reader :screen, :vte

end
