require 'rails_helper'

feature "Recorder tokens management" do

  let!(:user) { create(:user) }

  scenario 'Listing tokens when user has none' do
    login_as user
    visit edit_user_path

    expect(page).to have_content('asciinema auth')
  end

  scenario 'Listing tokens when user has some' do
    api_token = create(:api_token, user: user)

    login_as user
    visit edit_user_path

    expect(page).to have_content(api_token.token)
    expect(page).to have_link('Revoke')
    expect(page).to have_no_content('asciinema auth')
  end

  scenario 'Revoking a token' do
    api_token = create(:api_token, user: user)

    login_as user
    visit edit_user_path

    click_on "Revoke"

    expect(page).to have_content(api_token.token)
    expect(page).to have_no_link('Revoke')
  end

end

