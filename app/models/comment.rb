class Comment < ActiveRecord::Base

  validates :body, :presence => true
  validates :asciicast_id, :presence => true
  validates :user_id, :presence => true

  belongs_to :user
  belongs_to :asciicast

  attr_accessible :body

  def created
    created_at.to_s
  end

  def as_json(options = {})
    super({
      :include => {
        :user => {
          :only => [ :nickname, :avatar_url ]
         }
       },
       :methods => [:created]
    }.merge(options))
  end

end
