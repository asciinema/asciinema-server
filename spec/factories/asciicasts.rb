# Read about factories at http://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :asciicast do
    user_id 1
    stdout "MyString"
    stdout_timing "MyString"
    title "MyString"
    duration 1
    recorded_at "2011-11-23 22:06:07"
    terminal_type "MyString"
    terminal_columns 1
    terminal_lines 1
    command "MyString"
    shell "MyString"
    uname "MyString"
  end
end
