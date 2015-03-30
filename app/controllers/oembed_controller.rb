class OembedController < ApplicationController

  def show
    url = URI.parse(params[:url])

    if url.path =~ %r{^/a/(\d+)$}
      id = $1
      asciicast = AsciicastDecorator.new(Asciicast.find(id))

      respond_to do |format|
        format.json do
          render json: oembed_response(asciicast)
        end
        format.xml do
          render xml: oembed_response(asciicast).to_xml(root: 'oembed')
        end
      end
    else
      head :bad_request
    end
  end

  private

  def oembed_response(asciicast)
    asciicast_image_generator.generate(asciicast) if asciicast.image_stale?

    width, height = asciicast.image_width, asciicast.image_height

    if params[:maxwidth]
      width, height = size_smaller_than(width, height, params[:maxwidth], params[:maxheight])
    end

    oembed = {
      type: 'rich',
      version: 1.0,
      title: asciicast.title,
      author_name: asciicast.user.display_name,
      author_url: profile_url(asciicast.user),
      provider_name: 'asciinema',
      provider_url: root_url,
      thumbnail_url: asciicast.image_url,
      thumbnail_width: width,
      thumbnail_height: height,
      html: render_html(asciicast, width),
      width: width,
      height: height,
    }
  end

  def render_html(asciicast, width)
    render_to_string(
      template: 'oembed/show.html.erb',
      layout: false,
      locals: { asciicast: asciicast, width: width }
    ).chomp
  end

  def size_smaller_than(width, height, max_width, max_height)
    fw = Rational(max_width, width)
    fh = Rational(max_height, height)

    if fw > 1 && fh > 1
      [width, height]
    else
      f = [fw, fh].min
      [(Rational(width) * f).to_i, (Rational(height) * f).to_i]
    end
  end

  def asciicast_image_generator
    AsciicastImageGenerator.new(self)
  end

end
