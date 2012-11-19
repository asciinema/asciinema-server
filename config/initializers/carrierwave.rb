CarrierWave.configure do |config|
  if CFG['CARRIERWAVE_STORAGE'] == :fog
    config.storage = :fog

    config.fog_credentials = {
      :provider              => 'AWS',
      :aws_access_key_id     => CFG['AWS_ACCESS_KEY_ID'],
      :aws_secret_access_key => CFG['AWS_SECRET_ACCESS_KEY'],
      :region                => CFG['AWS_REGION']
    }
    config.fog_directory = CFG['AWS_BUCKET']
  else
    config.storage = :file
  end

  if Rails.env.test?
    config.storage = :file
    config.enable_processing = false
  end
end
