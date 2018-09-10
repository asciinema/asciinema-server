class ApiToken < ActiveRecord::Base
  belongs_to :user
end
