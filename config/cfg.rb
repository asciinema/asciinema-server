require 'uri'

module Asciinema
  class Configuration
    include Virtus.model

    attribute :base_url,                       String, default: 'http://localhost:3000'
    attribute :bugsnag_api_key,                String
    attribute :aws_access_key_id,              String
    attribute :aws_secret_access_key,          String
    attribute :s3_bucket,                      String
    attribute :s3_region,                      String
    attribute :carrierwave_storage_dir_prefix, String, default: 'uploads/'
    attribute :google_analytics_id,            String
    attribute :home_asciicast_id,              Integer
    attribute :secret_key_base,                String
    attribute :admin_ids,                      Array[Integer]
    attribute :smtp_settings,                  Hash
    attribute :from_email,                     String, default: "asciinema <hello@asciinema.org>"

    def home_asciicast
      if home_asciicast_id
        Asciicast.find(home_asciicast_id)
      else
        Asciicast.non_private.order(:id).first
      end
    end

    def scheme
      URI.parse(base_url).scheme
    end

    def hostname_with_port
      uri = URI.parse(base_url)
      hwp = uri.hostname

      if uri.port != uri.default_port
        hwp = "#{hwp}:#{uri.port}"
      end

      hwp
    end

    def ssl?
      scheme == 'https'
    end

  end
end

cfg_file = File.expand_path(File.dirname(__FILE__) + '/asciinema.yml')
cfg = YAML.load_file(cfg_file) || {} rescue {}
env = Hash[ENV.to_h.map { |k, v| [k.downcase, v] }]
cfg.merge!(env)

::CFG = Asciinema::Configuration.new(cfg)
