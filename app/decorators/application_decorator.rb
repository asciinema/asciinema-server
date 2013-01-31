class ApplicationDecorator < Draper::Decorator

  delegate_all

  def as_json(*args)
    model.as_json(*args)
  end

  def markdown(text)
    MKD_SAFE_RENDERER.render(text).html_safe
  end

end
