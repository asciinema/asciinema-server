require 'uri'

module Asciinema
  class Configuration
    include Virtus.model

    attribute :url_scheme,                     String, default: "http"
    attribute :url_host,                       String, default: "localhost"
    attribute :url_port,                       Integer, default: 3000
    attribute :bugsnag_api_key,                String
    attribute :aws_access_key_id,              String
    attribute :aws_secret_access_key,          String
    attribute :s3_bucket,                      String
    attribute :s3_region,                      String
    attribute :carrierwave_storage_dir_prefix, String, default: 'uploads/'
    attribute :google_analytics_id,            String
    attribute :home_asciicast_id,              String
    attribute :secret_key_base,                String
    attribute :session_encryption_salt,        String, default: 'encrypted cookie'
    attribute :session_signing_salt,           String, default: 'signed encrypted cookie'
    attribute :admin_ids,                      Array[Integer]
    attribute :smtp_settings,                  Hash
    attribute :smtp_from_address,              String

    def home_asciicast
      if home_asciicast_id
        Asciicast.find_by_id_or_secret_token!(home_asciicast_id)
      else
        Asciicast.non_private.order(:id).first
      end
    end

    def ssl?
      url_scheme == 'https'
    end

    def smtp_from_address
      super || "asciinema <hello@#{url_host}>"
    end
  end
end

cfg_file = File.expand_path(File.dirname(__FILE__) + '/asciinema.yml')
cfg = YAML.load_file(cfg_file) || {} rescue {}
env = Hash[ENV.to_h.map { |k, v| [k.downcase, v] }]
cfg.merge!(env)

::CFG = Asciinema::Configuration.new(cfg)
