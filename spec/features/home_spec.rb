require 'spec_helper'

feature "Homepage", :js => true do

  let!(:user) { create(:user) }
  let!(:asciicast) { create(:asciicast, :user => user) }

  scenario 'Visiting' do
    visit root_path

    expect(page).to have_link('Browse')
    expect(page).to have_link('Docs')
    expect_browse_links
    expect(page).to have_content(/Recent Asciicasts/i)
    expect(page).to have_link("bashing")
    expect(page).to have_selector('#about .play-button')
  end

end
