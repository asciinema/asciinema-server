require 'rails_helper'

feature "Static pages" do

  scenario 'Visiting "about" page' do
    visit about_path

    within('.main') do
      expect(page).to have_content(/About Asciinema/i)
    end
  end

  scenario 'Visiting "terms of service" page' do
    visit tos_path

    within('.main') do
      expect(page).to have_content(/Terms of Service/i)
    end
  end

  scenario 'Visiting "contributing" page' do
    visit contributing_path

    within('.main') do
      expect(page).to have_content(/Contributing/i)
    end
  end

end
