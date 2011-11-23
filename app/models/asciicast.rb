class Asciicast < ActiveRecord::Base
  validates :terminal_columns, :terminal_lines, :duration, :presence => true
end
