module AsciicastsHelper

  def player(asciicast, options = PlaybackOptions.new, skip_titlebar = false)
    render 'asciicasts/player',
      asciicast: AsciicastSerializer.new(asciicast, v0: options.v0),
      options: options,
      skip_titlebar: skip_titlebar
  end

  def player_tag(asciicast, options, skip_titlebar)
    opts = {
      id: 'player',
      src: asciicast.url,
      cols: options.cols || asciicast.width,
      rows: options.rows || asciicast.height,
      poster: options.poster || base64_poster(asciicast),
      speed: options.speed,
      autoplay: options.autoplay,
      loop: options.loop,
      'start-at' => options.t,
      'font-size' => options.size,
      theme: options.theme,
    }

    if options.preload # because {preload: false} gets converted to "preload=preload" by Rails
      opts[:preload] = true
    end

    unless skip_titlebar
      opts.merge!(
        title: asciicast.title,
        author: asciicast.author_display_name,
        'author-url' => asciicast.author_url,
        'author-img-url' => asciicast.author_avatar_url,
      )
    end

    content_tag('asciinema-player', '', opts)
  end

  def embed_script(asciicast)
    src = asciicast_url(asciicast, format: :js)
    id = "asciicast-#{asciicast.to_param}"
    %(<script type="text/javascript" src="#{src}" id="#{id}" async></script>)
  end

  def embed_html_link(asciicast)
    img_src = asciicast_url(asciicast, format: :png)
    url = asciicast_url(asciicast)
    %(<a href="#{url}" target="_blank"><img src="#{img_src}" /></a>)
  end

  def embed_markdown_link(asciicast)
    img_src = asciicast_url(asciicast, format: :png)
    url = asciicast_url(asciicast)
    "[![asciicast](#{img_src})](#{url})"
  end

  private

  def base64_poster(asciicast)
    'data:application/json;base64,' + Base64.encode64(JSON.generate(asciicast.snapshot, ascii_only: true))
  end

end
