module Asciinema
  module FixtureHelpers
    extend self

    def fixture_file(name, mime_type)
      fixture_file_upload("spec/fixtures/#{name}", mime_type)
    end

  end
end
