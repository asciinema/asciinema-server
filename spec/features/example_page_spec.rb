require 'spec_helper'

feature "Example page with embedded player", :js => true do

  let!(:asciicast) { create(:asciicast) }

  scenario 'Visiting' do
    visit example_asciicast_path(asciicast)

    within_frame "asciicast-iframe-#{asciicast.id}" do
      expect(page).to have_selector('.play-button')
    end
  end

end
