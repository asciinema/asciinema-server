class SetAuthTokenForExistingUsers < ActiveRecord::Migration
  def up
    User.find_each do |user|
      user.update_attribute(:auth_token, SecureRandom.urlsafe_base64)
    end
  end

  def down
  end
end
