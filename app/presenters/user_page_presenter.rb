class UserPagePresenter

  PER_PAGE = 15

  attr_reader :user, :current_user, :page, :per_page

  def self.build(user, current_user, page = nil, per_page = nil)
    new(user.decorate, current_user, page || 1, per_page || PER_PAGE)
  end

  def initialize(user, current_user, page, per_page)
    @user         = user
    @current_user = current_user
    @page         = page
    @per_page     = per_page
  end

  def title
    "#{user.username}'s profile".html_safe
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
    user.editable_by?(current_user)
  end

  def asciicast_count_text(h)
    count = h.pluralize(user.asciicast_count, 'asciicast')
    "#{count} by #{user.username}"
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
    PaginatingDecorator.new(user.paged_asciicasts(page, per_page))
  end

end
