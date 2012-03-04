# Read about factories at http://github.com/thoughtbot/factory_girl

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
    stdout { File.open('spec/fixtures/asciicasts/1/stdout') }
    stdout_timing { File.open('spec/fixtures/asciicasts/1/stdout.time') }
  end
end
