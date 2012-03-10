if CFG.carrierwave_storage == :fog
  CarrierWave.configure do |config|
    config.fog_credentials = {
      :provider              => 'AWS',
      :aws_access_key_id     => CFG.carrierwave_fog.aws_access_key_id,
      :aws_secret_access_key => CFG.carrierwave_fog.aws_secret_access_key,
      :region                => CFG.carrierwave_fog.aws_region
    }
    config.fog_directory = CFG.carrierwave_fog.bucket
  end
end
