class AsciicastParams

  def self.build(params, user_agent)
    meta = params[:meta]

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
    }

    if meta['uname'] # old client, with useless, random user_agent
      attributes[:uname] = meta['uname']
    else
      attributes[:user_agent] = user_agent
    end

    attributes
  end

end
