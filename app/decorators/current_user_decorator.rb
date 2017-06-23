class CurrentUserDecorator < UserDecorator

  def display_name
    model.username || model.email || model.temporary_username || "Me"
  end

end
