class Api::AsciicastsController < ApplicationController

  skip_before_filter :verify_authenticity_token

  def create
    asciicast = AsciicastCreator.new.create(params[:asciicast], request.headers)
    render :text => asciicast_url(asciicast), :status => :created,
                                              :location => asciicast
  rescue ActiveRecord::RecordInvalid => e
    render :nothing => true, :status => 422
  end

end
