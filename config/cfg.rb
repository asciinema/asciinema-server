module Asciinema
  class Configuration
    include Virtus.model

    attribute :add_this_profile_id,            String
    attribute :bugsnag_api_key,                String
    attribute :aws_access_key_id,              String
    attribute :aws_bucket,                     String
    attribute :aws_region,                     String
    attribute :aws_secret_access_key,          String
    attribute :carrierwave_storage,            String, default: 'file'
    attribute :carrierwave_storage_dir_prefix, String, default: 'uploads/'
    attribute :google_analytics_id,            String
    attribute :home_asciicast_id,              Integer
    attribute :scheme,                         String, default: 'http'
    attribute :host,                           String, default: 'localhost:3000'
    attribute :secret_token,                   String, default: '21deaa1a1228e119434aa783ecb4af21be7513ff1f5b8c1d8894241e5fc70ad395db72c8c1b0508a0ebb994ed88a8d73f6c84e44f7a4bc554a40d77f9844d2f4'
    attribute :admin_ids,                      Array[Integer]
    attribute :smtp_settings,                  Hash
    attribute :from_email,                     String, default: "Asciinema <hello@asciinema.org>"

    def home_asciicast
      asciicast = if home_asciicast_id
        Asciicast.find(home_asciicast_id)
      else
        Asciicast.last
      end
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
