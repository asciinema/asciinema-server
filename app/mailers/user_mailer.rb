class UserMailer < ActionMailer::Base
  default from: "hello@ascii.io"

  def new_comment_email(user, comment)
    @comment = comment
    @author = comment.user
    @asciicast = AsciicastDecorator.new(@comment.asciicast)

    to = "~#{user.nickname} <#{user.email}>"
    subject = %(New comment for #{@asciicast.smart_title})
    mail :to => to, :subject => subject
  end
end
