class StdinDataUploader < CompressedFileUploader

  def store_dir
    store_dir_prefix +
      "#{model.class.to_s.underscore}/stdin/#{model.id}"
  end

end
