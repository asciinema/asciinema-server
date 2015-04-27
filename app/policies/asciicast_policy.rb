class AsciicastPolicy < ApplicationPolicy

  class Scope < Struct.new(:user, :scope)
    def resolve
      scope
    end
  end

  def permitted_attributes
    if user.admin? || record.owner?(user)
      attrs = [:title, :description, :theme_name, :snapshot_at]
      attrs << :featured if change_featured?
      attrs << :private if change_visibility?

      attrs
    else
      []
    end
  end

  def update?
    return false unless user

    user.admin? || record.owner?(user)
  end

  def destroy?
    return false unless user

    user.admin? || record.owner?(user)
  end

  def change_featured?
    return false unless user

    user.admin?
  end

  def change_visibility?
    return false unless user

    user.admin?
  end

end
