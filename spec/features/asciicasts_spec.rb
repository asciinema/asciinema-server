require 'spec_helper'

feature "Asciicast lists" do

  let!(:asciicast) { load_asciicast(1) }

  scenario 'Visiting all' do
    visit browse_path

    expect(page).to have_content(/All Asciicasts/i)
    expect_browse_links
    expect(page).to have_link("##{asciicast.id}")
    expect(page).to have_selector('.supplimental .play-button')
  end

  scenario 'Visiting popular' do
    visit popular_path

    expect(page).to have_content(/Popular Asciicasts/i)
    expect_browse_links
    expect(page).to have_link("##{asciicast.id}")
    expect(page).to have_selector('.supplimental .play-button')
  end

end
