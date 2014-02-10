class AsciicastParams

  def self.build(params, user_agent)
    meta = JSON.parse(params[:meta].read)

    attributes = {
      stdout_data:      params[:stdout],
      stdout_timing:    params[:stdout_timing],
      stdin_data:       params[:stdin],
      stdin_timing:     params[:stdin_timing],
      username:         meta['username'],
      duration:         meta['duration'],
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
      attributes[:user_agent] = user_agent
    end

    assign_user_or_token(attributes, meta)

    attributes
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
