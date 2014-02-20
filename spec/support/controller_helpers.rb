module Asciinema
  module ControllerHelpers

    def login_as(user)
      controller.current_user = user
    end

  end
end
