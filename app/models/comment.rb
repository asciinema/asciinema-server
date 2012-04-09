class Comment < ActiveRecord::Base

  validates :body, :presence => true
  validates :asciicast_id, :presence => true
  validates :user_id, :presence => true

  belongs_to :user
  belongs_to :asciicast, :counter_cache => true

  attr_accessible :body

end
