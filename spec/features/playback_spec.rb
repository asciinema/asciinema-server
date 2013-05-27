require 'spec_helper'

describe 'Asciicast playback', :js => true, :slow => true do

  def visit_asciicast(id)
    asciicast = load_asciicast(id)
    visit "/a/#{asciicast.id}/raw?speed=5"
  end

  def inject_on_finished_callback
    page.execute_script(<<EOS)
      window.player.movie.on('finished', function() {
        $('body').append('<span class=\"finished\"></span>');
      })
EOS
  end

  Dir['spec/fixtures/asciicasts/*'].each do |dir|
    id = dir[/\d+/]

    describe "from fixture #{id}" do
      before do
        @old_wait_time = Capybara.default_wait_time
        Capybara.default_wait_time = 120
      end

      after do
        Capybara.default_wait_time = @old_wait_time
      end

      it "is successful" do
        visit_asciicast(id)
        find(".play-button").find(".arrow").click
        inject_on_finished_callback
        page.should have_selector('body .finished')
      end
    end
  end

end
