class CurrentUserDecorator < UserDecorator

  def display_name
    model.username || model.email
  end

end
