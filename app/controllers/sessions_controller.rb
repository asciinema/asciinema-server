class SessionsController < ApplicationController

  def destroy
    self.current_user = nil
    redirect_to root_path, notice: "See you later!"
  end

end
