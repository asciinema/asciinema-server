require 'spec_helper'

feature "User session" do

  scenario "Creating a session" do
    visit root_path

    click_on 'Log in'

    expect(page).to have_content('Persona')
  end

end
