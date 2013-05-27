require 'spec_helper'

feature "Docs" do

  scenario 'Visiting about page' do
    visit docs_path(:about)

    within('.main') do
      expect(page).to have_content('About')
    end

    expect_doc_links
  end

  scenario 'Visiting getting started page' do
    visit docs_path(:record)

    within('.main') do
      expect(page).to have_content('Getting started')
    end

    expect_doc_links
  end

  scenario 'Visiting options page' do
    visit docs_path(:options)

    within('.main') do
      expect(page).to have_content('Recorder options')
    end

    expect_doc_links
  end

end
