class AsciicastParams

  def self.from_format_0_request(params, user_agent)
    meta = params[:meta]

    attributes = {
      version:          0,
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

    if meta['uname'] # old client, with useless user_agent
      attributes[:uname] = meta['uname']
    else
      attributes[:user_agent] = user_agent
    end

    attributes
  end

  def self.from_format_1_request(asciicast_file, user_agent)
    asciicast = Oj.sc_parse(AsciicastHandler.new, asciicast_file)
    env = asciicast['env']

    {
      version: 1,
      terminal_columns: asciicast['width'],
      terminal_lines:   asciicast['height'],
      duration:         asciicast['duration'],
      command:          asciicast['command'],
      title:            asciicast['title'],
      shell:            env && env['SHELL'],
      terminal_type:    env && env['TERM'],
      file:             asciicast_file,
      user_agent:       user_agent,
    }
  end

  class AsciicastHandler < ::Oj::ScHandler
    META_ATTRIBUTES = %w[width height duration command title env SHELL TERM]

    def hash_start
      {}
    end

    def hash_set(h, k, v)
      if META_ATTRIBUTES.include?(k)
        h[k] = v
      end
    end
  end

end
