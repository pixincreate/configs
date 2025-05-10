---This function will return true if it is day time
---
---@return boolean
local is_day = function()
  local current_hour = tonumber(os.date("%H"))
  if current_hour > 11 and current_hour < 18 then
    return true
  else
    return false
  end
end

---This function will execute the function passed to it if the feature is available
---example usage:
---gate("win32", function() print("I'm on windows") end)
---
---@param feature table|nil|string
---@param fun function
---@return nil
local gated_execute = function(feature, fun)
  -- check if the feature is a list or value
  if type(feature) == "table" then
    for _, f in ipairs(feature) do
      if vim.fn.has(f) == 0 then
        return
      end
    end
    fun()
  elseif type(feature) == "nil" then
    fun()
  elseif type(feature) == "string" then
    if vim.fn.has(feature) == 1 then
      fun()
    end
  else
    error("Invalid feature type")
  end
end


---join
---@param list table<string, string>
---@return string
local function join(list)
  local output = nil
  for key, value in pairs(list) do
    if output == nil then
      output = key .. ":" .. value
    else
      output = output .. "," .. key .. ":" .. value
    end
  end
  return output
end

---load_project
---@param directory string
---@return table
local function load_project(directory)
  -- change the directory to the project directory
  vim.cmd("cd " .. directory)
end

return {
  is_day = is_day,
  gate = gated_execute,
  join = join
}
