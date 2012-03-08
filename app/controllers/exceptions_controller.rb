class ExceptionsController < ApplicationController

  def not_found
    respond_to do |format|
      format.any do
        render :text => 'Requested resource not found', :status => 404
      end

      format.html do
        render :status => 404
      end
    end
  end

end
