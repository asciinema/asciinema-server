class Bzip2Uploader < BaseUploader

  def decompressed
    return unless file

    unless @decompressed
      cache_stored_file! unless cached?

      file = IO.popen("bzip2 -d -c #{path}", "r")
      @decompressed = file.read
      file.close
    end

    @decompressed
  end

end
