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
      FactoryGirl.create(
        :asciicast,
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

  end
end
