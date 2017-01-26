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
  elsif CFG.carrierwave_storage == 'file'
    config.root = Rails.root
  end
end

if File.exists?(Rails.root.to_s + "/public/uploads/asciicast")
  raise "Please move all directories from ./public/uploads/ to ./uploads/"
end

# fix filename (remove ?AWSAccessKeyId=...)
CarrierWave::Storage::Fog::File.class_eval do
  def filename(options = {})
    if file_url = url(options)
      file_url.gsub(/.*\/(.*?$)/, '\1').sub(/\?.*$/, '')
    end
  end
end
