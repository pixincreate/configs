local wezterm = require 'wezterm'
local config = {};

if wezterm.config_builder then
  config = wezterm.config_builder()
end

config = require("loader")["global"](config)
config = require("loader")[wezterm.target_triple](config)


return config
