class ExceptionsController < ApplicationController

  def not_found
    respond_to do |format|
      format.any { render :text => 'Requested resource not found', :status => 404 }
      format.html { render :status => 404 }
    end
  end

end
