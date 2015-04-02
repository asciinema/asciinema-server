class ApiTokenPolicy < ApplicationPolicy

  def destroy?
    return false unless user

    user.admin? || record.user == user
  end

end
