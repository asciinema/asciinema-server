require 'rails_helper'

feature "Asciicast page", :js => true do

  let!(:user) { create(:user, username: 'aaron') }
  let!(:asciicast) { create(:asciicast, user: user, title: 'the title') }
  let!(:other_asciicast) { create(:asciicast, user: user) }

  scenario 'Visiting as guest' do
    visit asciicast_path(asciicast)

    expect(page).to have_content('the title')
    expect(page).to have_link('aaron')
    expect(page).to have_link('Share')
    expect(page).to have_selector('.cinema .play-button')
  end

  scenario 'Visiting as guest when asciicast is private' do
    asciicast.update(private: true)

    visit asciicast_path(asciicast)

    expect(page).to have_content('the title')
    expect(page).to have_link('aaron')
    expect(page).to have_link('Share')
    expect(page).to have_selector('.cinema .play-button')
  end

end
