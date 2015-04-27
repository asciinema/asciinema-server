CarrierWave.configure do |config|
  if CFG.carrierwave_storage == 'fog'
    config.storage = :fog

    config.fog_credentials = {
      :provider              => 'AWS',
      :aws_access_key_id     => CFG.aws_access_key_id,
      :aws_secret_access_key => CFG.aws_secret_access_key,
      :region                => CFG.aws_region
    }
    config.fog_directory = CFG.aws_bucket
    config.fog_public = false
  end
end
