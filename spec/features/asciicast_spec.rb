require 'spec_helper'

feature "Asciicast page", :js => true do

  let!(:user) { create(:user, nickname: 'aaron') }
  let!(:asciicast) { create(:asciicast, user: user, title: 'the title') }
  let!(:other_asciicast) { create(:asciicast, user: user) }

  scenario 'Visiting as guest' do
    visit asciicast_path(asciicast)

    expect(page).to have_content('the title')
    expect(page).to have_link('aaron')
    expect(page).to have_link('Embed')
    expect(page).to have_selector('.cinema .play-button')
  end

end
