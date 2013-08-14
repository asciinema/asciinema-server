class UserMailer < ActionMailer::Base
  default :from => "ascii.io <hello@ascii.io>"
  helper :application

  def new_comment_email(user, comment)
    @comment = comment
    @author = UserDecorator.new(comment.user)
    @asciicast = AsciicastDecorator.new(@comment.asciicast)

    user = UserDecorator.new(user)
    to = "#{user.nickname} <#{user.email}>"
    subject = %(New comment for #{@asciicast.title})
    mail :to => to, :subject => subject
  end
end
