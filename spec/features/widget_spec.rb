require 'spec_helper'

class TestWidgetController < ActionController::Base

  def show
    render :text => <<EOS
      <html>
        <head></head>
        <body>
          <script type="text/javascript" src="http://0.0.0.0:#{request.port}/a/#{params[:id]}.js" id="asciicast-#{params[:id]}" async></script>
        </body>
      </html>
EOS
  end

end

feature "Embeddable widget", :js => true do

  let!(:asciicast) { create(:asciicast) }

  scenario 'Visiting a page with the widget embed script' do
    visit "/test/widget/#{asciicast.id}"

    within_frame "asciicast-iframe-#{asciicast.id}" do
      expect(page).to have_selector('.play-button')
    end
  end

end
