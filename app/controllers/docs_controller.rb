class DocsController < ApplicationController
  layout 'docs'

  rescue_from ActionView::MissingTemplate, with: :handle_not_found

  def show
    @current_category = params[:page].to_sym
    render params[:page]
  end
end
