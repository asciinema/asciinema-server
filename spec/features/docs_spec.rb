require 'spec_helper'

feature "Docs" do

  scenario 'Visiting "how it works" page' do
    visit docs_path('how-it-works')

    within('.main') do
      expect(page).to have_content('How it works')
    end

    expect_doc_links
  end

  scenario 'Visiting "getting started" page' do
    visit docs_path('getting-started')

    within('.main') do
      expect(page).to have_content('Getting started')
    end

    expect_doc_links
  end

  scenario 'Visiting installation page' do
    visit docs_path(:installation)

    within('.main') do
      expect(page).to have_content('Installation')
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

  scenario 'Visiting embedding page' do
    visit docs_path(:embedding)

    within('.main') do
      expect(page).to have_content('Embedding')
    end

    expect_doc_links
  end

  scenario 'Visiting FAQ page' do
    visit docs_path(:faq)

    within('.main') do
      expect(page).to have_content('Frequently Asked Questions')
    end

    expect_doc_links
  end

end
