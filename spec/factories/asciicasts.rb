# Read about factories at http://github.com/thoughtbot/factory_girl
include ActionDispatch::TestProcess

FactoryGirl.define do
  factory :asciicast do
    association :user
    title "bashing"
    duration 11.146430015563965
    recorded_at "2011-11-23 22:06:07"
    terminal_type "screen-256color"
    terminal_columns 96
    terminal_lines 26
    shell "/bin/zsh"
    uname "Linux 3.9.9-302.fc19.x86_64 #1 SMP Sat Jul 6 13:41:07 UTC 2013 x86_64"
    views_count 1
    stdout_data   { fixture_file_upload("spec/fixtures/stdout", "application/octet-stream") }
    stdout_timing { fixture_file_upload("spec/fixtures/stdout.time", "application/octet-stream") }
  end
end
