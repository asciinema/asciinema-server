require 'spec_helper'

feature "Asciicast page", :js => true do

  let(:asciicast) { load_asciicast(1) }

  scenario 'Visiting as guest' do
    visit asciicast_path(asciicast)

    expect(page).to have_content('Recorded')
    expect(page).to have_content('Viewed')
    expect(page).to have_content('OS')
    expect(page).to have_content('SHELL')
    expect(page).to have_content('TERM')
    expect(page).to have_selector('.play-button')
  end

end
