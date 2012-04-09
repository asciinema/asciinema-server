class CommentDecorator < ApplicationDecorator
  decorates :comment

  def created
    created_at && created_at.strftime("%Y-%m-%dT%H:%M:%S")
  end

  def as_json(opts = nil)
    opts ||= {}

    options = {
      :include => { :user => { :only => [:id, :nickname, :avatar_url] } }
    }
    options.merge!(opts)

    data = model.as_json(options)
    data['processed_body'] = markdown(data['body'])
    data['created'] = created

    data
  end

end
