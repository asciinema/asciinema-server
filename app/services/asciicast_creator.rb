class AsciicastCreator

  def create(attributes)
    attributes = prepare_attributes(attributes)
    options = { :without_protection => true }

    Asciicast.create!(attributes, options).tap do |asciicast|
      AsciicastWorker.perform_async(asciicast.id)
    end
  end

  private

  def prepare_attributes(attributes)
    meta = parse_meta_file(attributes[:meta])

    {
      :stdout_data      => attributes[:stdout],
      :stdout_timing    => attributes[:stdout_timing],
      :stdin_data       => attributes[:stdin],
      :stdin_timing     => attributes[:stdin_timing],
      :username         => meta['username'],
      :user_token       => meta['user_token'],
      :duration         => meta['duration'],
      :recorded_at      => meta['recorded_at'],
      :title            => meta['title'],
      :command          => meta['command'],
      :shell            => meta['shell'],
      :uname            => meta['uname'],
      :terminal_lines   => meta['term']['lines'],
      :terminal_columns => meta['term']['columns'],
      :terminal_type    => meta['term']['type'],
    }
  end

  def parse_meta_file(file)
    JSON.parse(file.read)
  end

end
