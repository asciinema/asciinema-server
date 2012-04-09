class Like < ActiveRecord::Base
  belongs_to :asciicast, :counter_cache => true
  belongs_to :user
end
