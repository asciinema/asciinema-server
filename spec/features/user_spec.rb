require 'rails_helper'

feature "User's profile" do

  let!(:user) { create(:user) }
  let!(:asciicast) { create(:asciicast, :user => user, :title => 'Tricks!') }

  scenario 'Visiting' do
    visit profile_path(user)

    expect(page).to have_content(/1 asciicast by #{user.username}/i)
    expect(page).to have_link('Tricks!')
    expect(page).to have_selector('.asciicast-list .play-button')
  end

  scenario 'Updating profile', js: true, unstable: true do
    login_as user

    within 'header' do
      click_on user.username
      click_on 'Settings'
    end

    fill_in 'Username', with: 'batman'
    click_on 'Save'

    within 'header' do
      expect(page).to have_content('batman')
    end
  end

end
