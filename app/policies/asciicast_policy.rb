class AsciicastPolicy < ApplicationPolicy

  class Scope < Struct.new(:user, :scope)
    def resolve
      scope
    end
  end

  def permitted_attributes
    if user.admin? || record.owner?(user)
      attrs = [:title, :description, :theme_name, :snapshot_at]
      attrs << :featured if user.admin?
      attrs << :private if record.owner?(user)

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

  def feature?
    return false unless user

    user.admin?
  end

  def unfeature?
    return false unless user

    user.admin?
  end

  def make_public?
    return false unless user

    record.owner?(user)
  end

  def make_private?
    return false unless user

    record.owner?(user)
  end

end
