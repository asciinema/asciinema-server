class AsciicastParams
  FormatError = Class.new(StandardError)

  def self.build(asciicast_params, user, user_agent)
    attributes = if asciicast_params.try(:respond_to?, :read)
      from_format_1_request(asciicast_params, user, user_agent)
    else
      from_format_0_request(asciicast_params, user, user_agent)
    end

    attributes.merge(private: user.new_asciicast_private?)
  end

  def self.from_format_0_request(params, user, user_agent)
    meta = params.delete(:meta)

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
      user:             user,
      version:          0,
    }

    if meta['uname'] # old client, with useless user_agent
      attributes[:uname] = meta['uname']
    else
      attributes[:user_agent] = user_agent
    end

    attributes
  end

  def self.from_format_1_request(asciicast_file, user, user_agent)
    begin
      asciicast = Oj.sc_parse(AsciicastHandler.new, asciicast_file)
    rescue Oj::ParseError
      raise FormatError, "This doesn't look like a valid asciicast file"
    end

    version = asciicast['version']

    if version != 1
      raise FormatError, "Unsupported asciicast format version: #{version}"
    end

    env = asciicast['env']

    {
      command:          asciicast['command'],
      duration:         asciicast['duration'],
      file:             asciicast_file,
      shell:            env && env['SHELL'],
      terminal_columns: asciicast['width'],
      terminal_lines:   asciicast['height'],
      terminal_type:    env && env['TERM'],
      title:            asciicast['title'],
      user:             user,
      user_agent:       user_agent,
      version:          version,
    }
  end

  class AsciicastHandler < ::Oj::ScHandler
    META_ATTRIBUTES = %w[version width height duration command title env SHELL TERM]

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
