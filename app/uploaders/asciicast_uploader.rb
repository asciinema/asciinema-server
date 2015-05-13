class AsciicastUploader < BaseUploader

  def absolute_url
    if CFG.carrierwave_storage == 'file'
      path
    else
      url
    end
  end

end
