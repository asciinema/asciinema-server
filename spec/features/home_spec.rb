require 'spec_helper'

feature "Homepage", :js => true do

  let!(:asciicast) { load_asciicast(1) }

  scenario 'Visiting' do
    visit root_path

    expect(page).to have_content(/Recent Asciicasts/i)
    expect(page).to have_link('Browse')
    expect(page).to have_link('Record')
    expect_browse_links
    expect(page).to have_link("##{asciicast.id}")
    expect(page).to have_selector('#about .play-button')
  end

end
