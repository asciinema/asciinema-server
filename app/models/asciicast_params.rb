class AsciicastParams

  def initialize(input)
    @input = input
  end

  def to_h
    attributes = {
      :stdout_data      => input[:stdout],
      :stdout_timing    => input[:stdout_timing],
      :stdin_data       => input[:stdin],
      :stdin_timing     => input[:stdin_timing],
      :username         => meta['username'],
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

    assign_user_or_token(attributes, meta)

    attributes
  end

  private

  attr_reader :input

  def meta
    @meta ||= JSON.parse(input[:meta].read)
  end

  def assign_user_or_token(attributes, meta)
    token = meta['user_token']

    if token.present?
      user_token = UserToken.find_by_token(token)

      if user_token
        attributes[:user_id] = user_token.user_id
      else
        attributes[:user_token] = token
      end
    end
  end

end
