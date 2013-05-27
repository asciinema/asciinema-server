# Read about factories at http://github.com/thoughtbot/factory_girl
include ActionDispatch::TestProcess

FactoryGirl.define do
  factory :asciicast do
    association :user
    title "bashing"
    duration 100
    recorded_at "2011-11-23 22:06:07"
    terminal_type "xterm"
    terminal_columns 80
    terminal_lines 25
    shell "/bin/bash"
    uname "uname"
    views_count 1
    stdout do
      fixture_file_upload("spec/fixtures/stdout", "application/octet-stream")
    end
    stdout_timing do
      fixture_file_upload("spec/fixtures/stdout", "application/octet-stream")
    end
  end
end
