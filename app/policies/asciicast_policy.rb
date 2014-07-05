class AsciicastPolicy < ApplicationPolicy

  class Scope < Struct.new(:user, :scope)
    def resolve
      scope
    end
  end

  def permitted_attributes
    if user.admin? || record.user == user
      attrs = [:title, :description, :theme_name]
      attrs << :featured if user.admin?

      attrs
    else
      []
    end
  end

  def update?
    return false unless user

    user.admin? || record.user == user
  end

  def destroy?
    return false unless user

    user.admin? || record.user == user
  end

  def feature?
    return false unless user

    user.admin?
  end

  def unfeature?
    return false unless user

    user.admin?
  end

end
