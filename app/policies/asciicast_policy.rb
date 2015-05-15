class AsciicastPolicy < ApplicationPolicy

  class Scope < Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.non_private
      end
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
    user.admin? || record.owner?(user)
  end

  def destroy?
    user.admin? || record.owner?(user)
  end

  def change_featured?
    user.admin?
  end

  def change_visibility?
    user.admin? || record.owner?(user)
  end

end
