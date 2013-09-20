class StdoutFramesUploader < BaseUploader

  def filename
    'stdout.json' if original_filename.present?
  end

end
