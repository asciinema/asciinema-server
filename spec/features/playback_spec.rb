require 'spec_helper'

describe 'Asciicast playback', :js => true, :slow => true do

  let(:asciicast) { create(:asciicast) }

  describe "from fixture" do
    before do
      @old_wait_time = Capybara.default_wait_time
      Capybara.default_wait_time = 15
    end

    after do
      Capybara.default_wait_time = @old_wait_time
    end

    it "is successful" do
      visit asciicast_path(asciicast, speed: 5)
      find(".start-prompt .play-button").click
      page.should have_css('.time-remaining', visible: false, text: '-00:0')
    end
  end

end
