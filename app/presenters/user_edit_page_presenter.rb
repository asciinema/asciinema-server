class UserEditPagePresenter

  attr_reader :user

  def initialize(user)
    @user = user
  end

  def active_tokens
    sort(user.active_api_tokens)
  end

  def revoked_tokens
    sort(user.revoked_api_tokens)
  end

  def show_tokens?
    !active_tokens.empty? || !revoked_tokens.empty?
  end

  def show_privacy_controls?
    user.supporter?
  end

  private

  def sort(tokens)
    tokens.sort_by { |token| token.created_at }.reverse
  end

end
