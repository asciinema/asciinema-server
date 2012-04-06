class AsciicastDecorator < ApplicationDecorator
  decorates :asciicast

  THUMBNAIL_WIDTH = 20
  THUMBNAIL_HEIGHT = 10

  def thumbnail
    if @thumbnail.nil?
      lines = model.snapshot.split("\n")

      top_lines = lines[0...THUMBNAIL_HEIGHT]
      top_text = prepare_lines(top_lines).join("\n")

      bottom_lines = lines.reverse[0...THUMBNAIL_HEIGHT].reverse
      bottom_text = prepare_lines(bottom_lines).join("\n")

      if top_text.gsub(/\s+/, '').size > bottom_text.gsub(/\s+/, '').size
        @thumbnail = top_text
      else
        @thumbnail = bottom_text
      end
    end

    @thumbnail
  end

  private

  def prepare_lines(lines)
    (THUMBNAIL_HEIGHT - lines.size).times { lines << '' }

    lines.map do |line|
      line = line[0...THUMBNAIL_WIDTH]
      line << ' ' * (THUMBNAIL_WIDTH - line.size)
      line
    end
  end
end
