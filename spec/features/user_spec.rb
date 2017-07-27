require 'rails_helper'

feature "User's profile" do

  let!(:user) { create(:user) }
  let!(:asciicast) { create(:asciicast, :user => user, :title => 'Tricks!') }

  scenario 'Visiting' do
    visit public_profile_path(username: user.username)

    expect(page).to have_content(/1 public asciicast by #{user.username}/i)
    expect(page).to have_link('Tricks!')
    expect(page).to have_selector('.asciicast-list .play-button')
  end

end
