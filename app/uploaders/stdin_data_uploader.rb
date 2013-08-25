class StdinDataUploader < Bzip2Uploader

  def store_dir
    store_dir_prefix +
      "uploads/#{model.class.to_s.underscore}/stdin/#{model.id}"
  end

end
