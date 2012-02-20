app_cfg_file = File.expand_path(File.dirname(__FILE__) + '/app.yml')
cfg_hash = YAML.load_file(app_cfg_file)[Rails.env]

local_cfg_file = File.expand_path(File.dirname(__FILE__) + '/local.yml')
local_hash = YAML.load_file(local_cfg_file)[Rails.env] rescue {}

cfg_hash.merge!(local_hash)

CFG = Confstruct::Configuration.new(cfg_hash)
