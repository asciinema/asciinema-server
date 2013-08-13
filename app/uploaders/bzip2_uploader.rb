class Bzip2Uploader < BaseUploader

  def decompressed_path
    return unless file
    out_path = "#{path}.decompressed"

    unless File.exist?(out_path)
      cache_stored_file! unless cached?
      system("bzip2 -d -k -c #{path} >#{out_path}")
    end

    out_path
  end

end
