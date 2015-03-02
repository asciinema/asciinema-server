class AsciicastUploader < BaseUploader

  def url
    url = super

    if url[0] == '/'
      path
    else
      url
    end
  end

end
