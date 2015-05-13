class AsciicastSerializer < ActiveModel::Serializer
  self.root = false

  attributes :id, :duration, :stdout_frames_url, :snapshot
  attribute :terminal_columns, key: :width
  attribute :terminal_lines, key: :height

  def id
    object.to_param
  end

  def private?
    object.private?
  end

end
