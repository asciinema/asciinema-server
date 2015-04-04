module Asciinema
  module Test
    module Authentication
      attr_accessor :current_user

      def ensure_authenticated!
        unauthenticated_user unless current_user
      end
    end

    module ControllerHelpers
      def login_as(user)
        controller.current_user = user
      end

      def logout
        controller.current_user = nil
      end
    end

    module FeatureHelpers
      def login_as(user)
        visit new_login_path
        fill_in :email, with: user.email
        click_button 'Log in'
        visit "/login/#{user.expiring_tokens.last.token}"
      end
    end
  end
end

RSpec.configure do |config|
  config.before(:each, type: :controller) do
    controller.class_eval { include Asciinema::Test::Authentication }
  end

  config.include Asciinema::Test::ControllerHelpers, type: :controller
  config.include Asciinema::Test::FeatureHelpers, type: :feature
end
