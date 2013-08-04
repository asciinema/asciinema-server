module AsciiIo
  module FeatureHelpers

    def uploaded_file(path, type)
      ActionDispatch::Http::UploadedFile.new(
        :filename => File.basename(path),
        :tempfile => File.open(path),
        :type => type
      )
    end

    def load_asciicast(id)
      AsciicastCreator.new.create(
        :meta => uploaded_file(
          "spec/fixtures/asciicasts/#{id}/meta.json",
        'application/json'
        ),
        :stdout => fixture_file_upload(
          "spec/fixtures/asciicasts/#{id}/stdout",
          "application/octet-stream"
        ),
        :stdout_timing => fixture_file_upload(
          "spec/fixtures/asciicasts/#{id}/stdout.time",
          "application/octet-stream"
        )
      )
    end

    def load_all_asciicasts
      Dir['spec/fixtures/asciicasts/*'].each do |dir|
        id = dir[/\d+/]
        load_asciicast(id)
      end
    end

    def expect_browse_links
      expect(page).to have_link('All')
      expect(page).to have_link('Popular')
    end

    def expect_doc_links
      expect(page).to have_link('About')
      expect(page).to have_link('Getting started')
      expect(page).to have_link('Recorder options')
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
