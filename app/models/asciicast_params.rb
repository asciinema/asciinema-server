class AsciicastParams

  def self.build(params, user_agent)
    meta = JSON.parse(params[:meta].read)

    attributes = {
      command:          meta['command'],
      duration:         meta['duration'],
      shell:            meta['shell'],
      stdin_data:       params[:stdin],
      stdin_timing:     params[:stdin_timing],
      stdout_data:      params[:stdout],
      stdout_timing:    params[:stdout_timing],
      terminal_columns: meta['term']['columns'],
      terminal_lines:   meta['term']['lines'],
      terminal_type:    meta['term']['type'],
      title:            meta['title'],
      user:             get_user(meta)
    }

    if meta['uname'] # old client, with useless, random user_agent
      attributes[:uname] = meta['uname']
    else
      attributes[:user_agent] = user_agent
    end

    attributes
  end

  def self.get_user(attributes)
    User.for_api_token(attributes['user_token'], attributes['username'])
  end

end
