class ApiTokenPolicy < ApplicationPolicy

  def destroy?
    user.is_admin? || record.user == user
  end

end
