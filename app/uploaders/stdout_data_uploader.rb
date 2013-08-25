class StdoutDataUploader < Bzip2Uploader

  def store_dir
    store_dir_prefix +
      "uploads/#{model.class.to_s.underscore}/stdout/#{model.id}"
  end

end
