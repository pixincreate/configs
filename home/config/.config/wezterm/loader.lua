local utils = require "utils"

--- Lazy load the configuration for the current system
--- @param relative_path string
--- @return fun(config: table): table
local helper = function(relative_path)
  return function(config)
    require(relative_path .. ".hooks")
    config = require(relative_path .. ".config")(config)
    config.keys = utils.join(config.keys, require(relative_path .. ".keys"))
    return config
  end
end

local loader = {
  ["global"] = helper("global"),
  ["x86_64-unknown-linux-gnu"] = helper("system.linux"),
  ["x86_64-apple-darwin"] = helper("system.mac"),
  ["aarch64-apple-darwin"] = helper("system.mac")
}


return loader
