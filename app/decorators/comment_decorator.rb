class CommentDecorator < ApplicationDecorator
  decorates :comment

  def as_json(*args)
    data = model.as_json(*args)
    data['processed_body'] = markdown(data['body'])
    data
  end

end
