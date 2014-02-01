defaults = {
  CARRIERWAVE_STORAGE:            'file',
  CARRIERWAVE_STORAGE_DIR_PREFIX: 'uploads/',
  HOME_CAST_ID:                   nil,
  AIRBRAKE_API_KEY:               nil,
  AIRBRAKE_HOST:                  nil,
  GOOGLE_ANALYTICS_ID:            nil,
  TWITTER_CONSUMER_KEY:           nil,
  TWITTER_CONSUMER_SECRET:        nil,
  GITHUB_CONSUMER_KEY:            nil,
  GITHUB_CONSUMER_SECRET:         nil,
  AWS_ACCESS_KEY_ID:              nil,
  AWS_SECRET_ACCESS_KEY:          nil,
  AWS_REGION:                     nil,
  AWS_BUCKET:                     nil,
  SECRET_TOKEN:                   '21deaa1a1228e119434aa783ecb4af21be7513ff1f5b8c1d8894241e5fc70ad395db72c8c1b0508a0ebb994ed88a8d73f6c84e44f7a4bc554a40d77f9844d2f4',
  LOCAL_PERSONA_JS:               true,
  SCHEME:                         'http',
  ADD_THIS_PROFILE_ID:            nil
}.stringify_keys!

cfg_file = File.expand_path(File.dirname(__FILE__) + '/asciinema.yml')
cfg_hash = YAML.load_file(cfg_file) || {} rescue {}

cfg = {}
cfg.merge!(defaults)
cfg.merge!(cfg_hash)
cfg.merge!(ENV)

module Asciinema
  class Configuration
    def initialize(cfg)
      @cfg = cfg
    end

    def method_missing(name, *args, &block)
      key = normalize_key(name)
      @cfg.key?(key) ? @cfg[key] : super
    end

    def respond_to_missing?(name, include_private = false)
      key = normalize_key(name)
      @cfg.key?(key) || super
    end

    def [](key)
      send(key)
    end

    def local_persona_js?
      local_persona_js.to_s == 'true'
    end

    def home_asciicast
      asciicast = if home_cast_id
        Asciicast.find(home_cast_id)
      else
        Asciicast.last
      end
    end

    def ssl?
      scheme == 'https'
    end

    private

    def normalize_key(key)
      key.to_s.upcase
    end
  end
end

::CFG = Asciinema::Configuration.new(cfg)
