require 'spec_helper'

feature "User session" do

  scenario "Logging in when nickname isn't returned by oauth provider" do
    set_omniauth(:github)

    visit root_path

    click_on 'Log in'
    click_on 'Log in via Github'

    fill_in 'Username', :with => 'foobar'
    click_button 'Create'

    expect(page).to have_content('Logged in!')
    within('header') do
      expect(page).to have_link('foobar')
    end
  end

  scenario 'Logging in when nickname is returned by oauth provider' do
    set_omniauth(:github, :nickname => 'hasiok')

    visit root_path

    click_on 'Log in'
    click_on 'Log in via Github'

    expect(page).to have_content('Logged in!')
    within('header') do
      expect(page).to have_link('hasiok')
    end
  end

  scenario 'Logging in when error is returned by oauth provider' do
    set_omniauth(:github, :message => :access_denied)

    visit root_path

    click_on 'Log in'
    click_on 'Log in via Github'

    expect(page).to have_content('Authentication failed')
  end

  scenario 'Logging out' do
    set_omniauth(:github, :nickname => 'hasiok')

    visit root_path

    click_on 'Log in'
    click_on 'Log in via Github'
    click_on 'Log out'

    expect(page).to have_content('Logged out!')
  end

end
