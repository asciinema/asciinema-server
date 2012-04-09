class CommentDecorator < ApplicationDecorator
  decorates :comment

  def created
    created_at && (h.time_ago_in_words(created_at) + " ago")
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
