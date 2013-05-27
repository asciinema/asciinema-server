require 'spec_helper'

feature "User's profile" do

  let!(:user) { create(:user) }
  let!(:asciicast) { create(:asciicast, :user => user, :title => 'Tricks!') }

  scenario 'Visiting' do
    visit profile_path(user)

    expect(page).to have_content(/Asciicasts by ~#{user.nickname}/i)
    expect(page).to have_content('1 asciicasts')
    expect(page).to have_link('Tricks!')
    expect(page).to have_selector('.supplimental .play-button')
  end

end
