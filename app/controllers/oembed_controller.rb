class OembedController < ApplicationController
  CELL_WIDTH = 7.22
  CELL_HEIGHT = 16
  BORDER_WIDTH = 12

  def show
    url = URI.parse(params[:url])

    if url.path =~ %r{^/a/([^/]+)$}
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
  rescue URI::InvalidURIError
    head :bad_request
  end

  private

  def oembed_response(asciicast)
    scale = AsciicastImageGenerator::PIXEL_DENSITY
    image_width = scale * (CELL_WIDTH * asciicast.width + BORDER_WIDTH).floor
    image_height = scale * (CELL_HEIGHT * asciicast.height + BORDER_WIDTH)

    width, height = size_smaller_than(
      image_width,
      image_height,
      params[:maxwidth] || image_width,
      params[:maxheight] || image_height
    )

    {
      type: 'rich',
      version: 1.0,
      title: asciicast.title,
      author_name: asciicast.user.display_name,
      author_url: profile_url(asciicast.user),
      provider_name: 'asciinema',
      provider_url: root_url,
      thumbnail_url: asciicast_url(asciicast, format: :png),
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

end
