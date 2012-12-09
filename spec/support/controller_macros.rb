module AsciiIo
  module ControllerMacros
    def login_as(user)
      controller.stub(:current_user => user)
    end
  end
end
