require 'rails_helper'

feature "Asciicast page", :js => true do

  let!(:user) { create(:user, username: 'aaron') }
  let!(:asciicast) { create(:asciicast, user: user, title: 'the title') }
  let!(:other_asciicast) { create(:asciicast, user: user) }

  scenario 'Visiting as guest' do
    visit asciicast_path(asciicast)

    expect(page).to have_content('the title')
    expect(page).to have_link('aaron')
    expect(page).to have_link('Embed')
    expect(page).to have_selector('.cinema .play-button')
  end

  def rgb(color)
    [ChunkyPNG::Color.r(color), ChunkyPNG::Color.g(color), ChunkyPNG::Color.b(color)]
  end

  scenario 'Requesting PNG' do
    visit asciicast_path(asciicast, format: :png)

    expect(current_path).to match(%r{/uploads/test/asciicast/image/\d+/\w+\.png$})

    png = ChunkyPNG::Image.from_file("#{Rails.root}/public/#{current_path}")

    # make sure there are black-ish borders
    expect(rgb(png[1, 1])).to eq([18, 19, 20])
    expect(rgb(png[png.width - 2, png.height - 2])).to eq([18, 19, 20])

    # check content color (blue background)
    expect(rgb(png[15, 15])).to eq([0, 175, 255])

    # make sure white SVG play icon is rendered correctly
    expect(rgb(png[png.width / 2, (png.height / 2) - 10])).to eq([255, 255, 255])

    # make sure PowerlineSymbols are rendered
    expect(rgb(png[144, 795])).to eq([0, 95, 255])
  end

end
