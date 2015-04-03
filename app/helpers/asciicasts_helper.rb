module AsciicastsHelper

  def player(asciicast, options = PlaybackOptions.new)
    render 'asciicasts/player', asciicast: AsciicastSerializer.new(asciicast),
                                options:   options
  end

  def screenshot_javascript_tag
    js = assets.find_asset('embed.js').to_s
    content_tag(:script, js.html_safe)
  end

  def screenshot_stylesheet_tag
    css = translate_asset_paths(assets.find_asset('screenshot.css').to_s)
    content_tag(:style, css.html_safe)
  end

  private

  def translate_asset_paths(css)
    css.gsub(/['"]\/assets\/(.+?)(-\w{32})?\.(.+?)['"]/) { |m|
      path = assets.find_asset("#{$1}.#{$3}").pathname
      "'#{path}'"
    }
  end

end
