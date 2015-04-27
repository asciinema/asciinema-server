class UserPagePresenter

  PER_PAGE = 15

  attr_reader :user, :current_user, :policy, :page, :per_page

  def self.build(user, current_user, page = nil, per_page = nil)
    policy = Pundit.policy(current_user, user)
    new(user.decorate, current_user, policy, page || 1, per_page || PER_PAGE)
  end

  def initialize(user, current_user, policy, page, per_page)
    @user         = user
    @current_user = current_user
    @policy       = policy
    @page         = page
    @per_page     = per_page
  end

  def title
    "#{user.display_name}'s profile".html_safe
  end

  def user_full_name
    user.full_name
  end

  def user_joined_at
    user.joined_at
  end

  def user_avatar_image_tag
    user.avatar_image_tag
  end

  def show_settings?
    policy.update?
  end

  def asciicast_count_text(h)
    if current_users_profile?
      count = user.asciicast_count
      if count > 0
        count = h.pluralize(count, 'asciicast')
        "You have recorded #{count}"
      else
        "Record your first asciicast"
      end
    else
      count = user.public_asciicast_count
      if count > 0
        count = h.pluralize(count, 'asciicast')
        "#{count} by #{user.display_name}"
      else
        "#{user.display_name} hasn't recorded anything yet"
      end
    end
  end

  def user_username
    user.username
  end

  def asciicasts
    @asciicasts ||= get_asciicasts
  end

  def current_users_profile?
    current_user && current_user == user
  end

  private

  def get_asciicasts
    asciicasts = user.paged_asciicasts(page, per_page, current_users_profile?)
    PaginatingDecorator.new(asciicasts)
  end

end
