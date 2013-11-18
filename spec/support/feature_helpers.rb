module Asciinema
  module FeatureHelpers

    def expect_browse_links
      expect(page).to have_link('All')
      expect(page).to have_link('Popular')
    end

    def expect_doc_links
      expect(page).to have_link('How it works')
      expect(page).to have_link('Getting started')
      expect(page).to have_link('Installation')
      expect(page).to have_link('Recorder options')
      expect(page).to have_link('Embedding')
      expect(page).to have_link('FAQ')
    end

    def set_omniauth(provider, opts = {})
      if opts[:message]
        OmniAuth.config.mock_auth[provider] = opts[:message]
      else
        OmniAuth.config.mock_auth[provider] = OmniAuth::AuthHash.new({
          :provider => provider.to_s,
          :uid => '123456',
          :info => { :nickname => opts[:nickname] },
          :extra => {
            :raw_info => {
              :avatar_url =>
                'http://gravatar.com/avatar/9cecfc695240b56e5d3c1a5dc3830967'
            }
          }
        })
      end
    end

  end
end
