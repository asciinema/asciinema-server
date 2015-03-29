class AsciicastUploader < BaseUploader

  def url
    if CFG.carrierwave_storage == 'file'
      path
    else
      super
    end
  end

end
