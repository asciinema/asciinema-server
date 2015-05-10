class UserPolicy < ApplicationPolicy

  class Scope < Struct.new(:user, :scope)
    def resolve
      scope
    end
  end

  def permitted_attributes
    [:username, :name, :email, :theme_name, :asciicasts_private_by_default]
  end

  def update?
    record == user
  end

end
