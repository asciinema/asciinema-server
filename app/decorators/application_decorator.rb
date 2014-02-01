class ApplicationDecorator < Draper::Decorator

  delegate_all

  def markdown(text)
    MKD_SAFE_RENDERER.render(text).html_safe
  end

end
