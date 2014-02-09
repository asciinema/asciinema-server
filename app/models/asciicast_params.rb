class AsciicastParams

  include Virtus.model

  attribute :stdout_data
  attribute :stdout_timing
  attribute :stdin_data
  attribute :stdin_timing
  attribute :username, String
  attribute :duration, Float
  attribute :recorded_at, DateTime
  attribute :title, String
  attribute :command, String
  attribute :shell, String
  attribute :terminal_lines, Integer
  attribute :terminal_columns, Integer
  attribute :terminal_type, String
  attribute :uname, String
  attribute :user_agent, String
  attribute :user_id, Integer
  attribute :api_token, String

  def self.build(params, headers)
    meta = JSON.parse(params[:meta].read)

    attributes = {
      stdout_data:      params[:stdout],
      stdout_timing:    params[:stdout_timing],
      stdin_data:       params[:stdin],
      stdin_timing:     params[:stdin_timing],
      username:         meta['username'],
      duration:         meta['duration'],
      recorded_at:      meta['recorded_at'],
      title:            meta['title'],
      command:          meta['command'],
      shell:            meta['shell'],
      terminal_lines:   meta['term']['lines'],
      terminal_columns: meta['term']['columns'],
      terminal_type:    meta['term']['type'],
    }

    if meta['uname']
      attributes[:uname] = meta['uname']
    else
      attributes[:user_agent] = headers['User-Agent']
    end

    assign_user_or_token(attributes, meta)

    new(attributes)
  end

  def self.assign_user_or_token(attributes, meta)
    token = meta['user_token']

    if token.present?
      api_token = ApiToken.find_by_token(token)

      if api_token
        attributes[:user_id] = api_token.user_id
      else
        attributes[:api_token] = token
      end
    end
  end

end
