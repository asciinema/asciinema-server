module Asciinema
  module FeatureHelpers

    def expect_browse_links
      expect(page).to have_link('All')
      expect(page).to have_link('Featured')
    end

    def expect_doc_links
      expect(page).to have_link('How it works')
      expect(page).to have_link('Getting started')
      expect(page).to have_link('Installation')
      expect(page).to have_link('Recorder options')
      expect(page).to have_link('Embedding')
      expect(page).to have_link('FAQ')
    end

  end
end
