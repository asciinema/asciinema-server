class UserPolicy < ApplicationPolicy

  class Scope < Struct.new(:user, :scope)
    def resolve
      scope
    end
  end

  def permitted_attributes
    attrs = [:username, :name, :email, :theme_name]
    attrs << :asciicasts_private_by_default if record.supporter?

    attrs
  end

  def update?
    record == user
  end

end
