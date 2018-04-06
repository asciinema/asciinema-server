require 'rails_helper'

feature "Homepage", :js => true do

  let!(:user) { create(:user) }
  let!(:asciicast) { create(:asciicast, user: user, title: 'the title', featured: true) }

  scenario 'Visiting' do
    visit root_path

    expect(page).to have_link('Explore')
    expect(page).to have_link('Docs')
    expect(page).to have_button('Start Recording')
    expect(page).to have_content(/Featured asciicasts/i)
    expect(page).to have_link("the title")
  end

end
