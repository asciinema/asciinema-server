module Asciinema
  module Test
    module Warden
      class EmailStrategy < ::Warden::Strategies::Base

        def valid?
          email.present?
        end

        def authenticate!
          user = User.find_by_email(email)
          user && success!(user)
        end

        private

        def email
          request.params['email']
        end

      end
    end

    module Authentication
      attr_accessor :current_user
    end

    module ControllerHelpers
      def login_as(user)
        controller.current_user = user
      end
    end

    module FeatureHelpers
      def login_as(user)
        visit edit_user_path(email: user.email)
        page.save_screenshot 'a.png'
      end
    end
  end
end

Warden::Strategies.add(:test, Asciinema::Test::Warden::EmailStrategy)

ApplicationController.class_eval do
  def warden_strategies
    [:test]
  end
end

RSpec.configure do |config|
  config.before(:each, type: :controller) do
    controller.class_eval { include Asciinema::Test::Authentication }
  end

  config.include Asciinema::Test::ControllerHelpers, type: :controller
  config.include Asciinema::Test::FeatureHelpers, type: :feature
end
