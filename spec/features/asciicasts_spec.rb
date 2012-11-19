require 'spec_helper'

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

def visit_asciicast(id)
  asciicast = load_asciicast(id)
  visit "/a/#{asciicast.id}/raw"
end

describe 'Asciicast', :type => :feature, :js => true do

  Dir['spec/fixtures/asciicasts/*'].each do |dir|
    id = dir[/\d+/]

    describe "from fixture #{id}" do
      it "successfully plays to the end" do
        visit_asciicast(id)
        find(".play-button").find(".arrow").click
      end
    end
  end

end
