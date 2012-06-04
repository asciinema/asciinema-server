class Api::AsciicastsController < ApplicationController
  skip_before_filter :verify_authenticity_token

  def create
    ac = Asciicast.new(params[:asciicast])

    if ac.save
      SNAPSHOT_QUEUE << ac.id
      render :text => asciicast_url(ac), :status => :created, :location => ac
    else
      render :text => ac.errors.full_messages, :status => 422
    end
  end

end
