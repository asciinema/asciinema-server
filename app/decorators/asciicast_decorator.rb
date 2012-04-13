class AsciicastDecorator < ApplicationDecorator
  decorates :asciicast

  THUMBNAIL_WIDTH = 20
  THUMBNAIL_HEIGHT = 10

  def as_json(*args)
    data = model.as_json(*args)
    data['escaped_stdout_data'] = escaped_stdout_data
    data['stdout_timing_data'] = stdout_timing_data

    data
  end

  def escaped_stdout_data
    if data = stdout.read
      data.bytes.map { |b| '\x' + format('%02x', b) }.join
    else
      nil
    end
  end

  def stdout_timing_data
    if data = stdout_timing.read
      Bzip2.uncompress(data).lines.map do |line|
        delay, n = line.split
        [delay.to_f, n.to_i]
      end
    else
      nil
    end
  end

  def os
    if uname =~ /Linux/
      'Linux'
    elsif uname =~ /Darwin/
      'OSX'
    else
      uname.split(' ', 2)[0]
    end
  end

  def shell_name
    File.basename(shell.to_s)
  end

  def smart_title
    if title.present?
      title
    elsif command.present?
      "$ #{command}"
    else
      "##{id}"
    end
  end

  def thumbnail(width = THUMBNAIL_WIDTH, height = THUMBNAIL_HEIGHT)
    if @thumbnail.nil?
      lines = model.snapshot.to_s.split("\n")

      top_lines = lines[0...height]
      top_text = prepare_lines(top_lines, width, height).join("\n")

      bottom_lines = lines.reverse[0...height].reverse
      bottom_text = prepare_lines(bottom_lines, width, height).join("\n")

      if top_text.gsub(/\s+/, '').size > bottom_text.gsub(/\s+/, '').size
        @thumbnail = top_text
      else
        @thumbnail = bottom_text
      end
    end

    @thumbnail
  end

  private

  def prepare_lines(lines, width, height)
    (height - lines.size).times { lines << '' }

    lines.map do |line|
      line = line[0...width]
      line << ' ' * (width - line.size)
      line
    end
  end
end
