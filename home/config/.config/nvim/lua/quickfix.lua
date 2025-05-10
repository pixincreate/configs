--[[
--
-- How to use quickfix list? search only
--
-- gr [pattern] . -R to search for a pattern
--
-- cope to open the quickfix list
--
-- ]]

local quickfixes = {
  rust = [[%Eerror\[%*[0-9E]\]:\ %m,%C\ \ \ \ -->\ %f:%l:%c,%Z]],
  python = [[%E\ %m,%C\ \ \ \ -->\ %f:%l:%c,%Z]],
};

local rust_quickfix = function()
  -- vim.cmd [[set efm=%Eerror\[%*[0-9E]\]:\ %m,%C\ \ \ \ -->\ %f:%l:%c,%Z]]
  vim.cmd(string.format('set efm=%s', quickfixes.rust))
end


return {
  rust_quickfix = rust_quickfix
}
