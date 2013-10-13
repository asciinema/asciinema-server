class AsciicastParams

  def initialize(params, headers)
    @params = params
    @headers = headers
  end

  def to_h
    attributes = {
      :stdout_data      => params[:stdout],
      :stdout_timing    => params[:stdout_timing],
      :stdin_data       => params[:stdin],
      :stdin_timing     => params[:stdin_timing],
      :username         => meta['username'],
      :duration         => meta['duration'],
      :recorded_at      => meta['recorded_at'],
      :title            => meta['title'],
      :command          => meta['command'],
      :shell            => meta['shell'],
      :terminal_lines   => meta['term']['lines'],
      :terminal_columns => meta['term']['columns'],
      :terminal_type    => meta['term']['type'],
    }

    if meta['uname']
      attributes[:uname] = meta['uname']
    else
      attributes[:user_agent] = headers['User-Agent']
    end

    assign_user_or_token(attributes, meta)

    attributes
  end

  private

  attr_reader :params, :headers

  def meta
    @meta ||= JSON.parse(params[:meta].read)
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
