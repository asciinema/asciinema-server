class Api::AsciicastsController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def create
    ac = Asciicast.new(params[:asciicast])

    if ac.save
      render :text => asciicast_url(ac), :status => 201
    else
      render :text => ac.errors.full_messages, :status => 422
    end
  end

end
