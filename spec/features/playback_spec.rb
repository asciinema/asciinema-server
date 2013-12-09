require 'spec_helper'

describe 'Asciicast playback', :js => true, :slow => true do

  let(:asciicast) { create(:asciicast) }

  describe "from fixture" do
    def inject_on_finished_callback
      page.execute_script(<<EOS)
        window.player.movie.on('finished', function() {
          $('body').append('<span class=\"finished\"></span>');
        })
EOS
    end

    before do
      @old_wait_time = Capybara.default_wait_time
      Capybara.default_wait_time = 120
    end

    after do
      Capybara.default_wait_time = @old_wait_time
    end

    it "is successful" do
      visit asciicast_path(asciicast, speed: 5)
      find(".play-button").find(".arrow").click
      inject_on_finished_callback
      expect(page).to have_selector('body .finished')
    end
  end

end
