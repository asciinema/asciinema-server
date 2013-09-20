class AsciicastSerializer < ActiveModel::Serializer
  self.root = false

  attributes :id, :duration, :stdout_frames_url, :snapshot
  attribute :terminal_columns, key: :width
  attribute :terminal_lines, key: :height
end
