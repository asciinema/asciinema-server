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
      cols: asciicast.width,
      rows: asciicast.height,
      poster: options.poster || base64_poster(asciicast),
      speed: options.speed,
      autoplay: options.autoplay,
      loop: options.loop,
      preload: options.preload,
      'start-at' => options.t,
      'font-size' => options.size,
      theme: options.theme,
    }

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

  def screenshot_javascript_tag
    js = assets.find_asset('embed.js').to_s
    content_tag(:script, js.html_safe)
  end

  def screenshot_stylesheet_tag
    css = translate_asset_paths(assets.find_asset('screenshot.css').to_s)
    content_tag(:style, css.html_safe)
  end

  def embed_script(asciicast)
    src = asciicast_url(asciicast, format: :js)
    id = "asciicast-#{asciicast.to_param}"
    %(<script type="text/javascript" src="#{src}" id="#{id}" async></script>)
  end

  def embed_html_link(asciicast)
    img_src = asciicast_url(asciicast, format: :png)
    url = asciicast_url(asciicast)
    width = %{width="#{asciicast.image_width}"} if asciicast.image_width
    %(<a href="#{url}" target="_blank"><img src="#{img_src}" #{width}/></a>)
  end

  def embed_markdown_link(asciicast)
    img_src = asciicast_url(asciicast, format: :png)
    url = asciicast_url(asciicast)
    "[![asciicast](#{img_src})](#{url})"
  end

  private

  def translate_asset_paths(css)
    css.gsub(/['"]\/assets\/(.+?)(-\w{64})?\.(.+?)['"]/) { |m|
      path = assets.find_asset("#{$1}.#{$3}").pathname
      "'#{path}'"
    }
  end

  def base64_poster(asciicast)
    'data:application/json;base64,' + Base64.encode64(asciicast.snapshot.to_json)
  end

end
