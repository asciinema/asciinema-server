require 'rails_helper'

feature "asciicast-as-png", needs_phantomjs_2_bin: true do

  let(:asciicast) { create(:asciicast) }

  scenario "Requesting PNG" do
    visit asciicast_path(asciicast, format: :png)

    expect(current_path).to match(%r{/uploads/test/asciicast/image/\d+/\w+\.png$})
  end

end
