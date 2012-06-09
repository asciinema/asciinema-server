if CFG['CARRIERWAVE_STORAGE'] == :fog
  CarrierWave.configure do |config|
    config.fog_credentials = {
      :provider              => 'AWS',
      :aws_access_key_id     => CFG['AWS_ACCESS_KEY_ID'],
      :aws_secret_access_key => CFG['AWS_SECRET_ACCESS_KEY'],
      :region                => CFG['AWS_REGION']
    }
    config.fog_directory = CFG['AWS_BUCKET']
  end
end
