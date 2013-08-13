class Bzip2Uploader < BaseUploader

  def decompressed_path
    return unless file

    cache_stored_file! unless cached?

    out_path = "#{current_path}.decompressed"

    unless File.exist?(out_path)
      system("bzip2 -d -k -c #{current_path} >#{out_path}")
    end

    out_path
  end

end
