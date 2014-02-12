class Comment < ActiveRecord::Base

  validates :body, :presence => true
  validates :asciicast, :presence => true
  validates :user, :presence => true

  belongs_to :user
  belongs_to :asciicast, :counter_cache => true

end
