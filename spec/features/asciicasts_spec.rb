require 'rails_helper'

feature "Asciicast lists" do

  let!(:asciicast) { create(:asciicast, title: 'foo bar') }
  let!(:featured_asciicast) { create(:asciicast, title: 'qux', featured: true) }

  scenario 'Visiting all' do
    visit browse_path

    expect(page).to have_content(/Public asciicasts/i)
    expect_browse_links
    expect(page).to have_link("foo bar")
    expect(page).to have_selector('.asciicast-list .play-button')
  end

  scenario 'Visiting featured' do
    visit asciicast_path(asciicast)
    visit category_path(:featured)

    expect(page).to have_content(/Featured asciicasts/i)
    expect_browse_links
    expect(page).to have_link("qux")
    expect(page).to have_selector('.asciicast-list .play-button')
  end

end
