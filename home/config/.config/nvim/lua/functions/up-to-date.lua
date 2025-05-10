-- This function checks if the current version of the neovim configuration is up-to-date.


-- This function checks if the current version of the neovim configuration is up-to-date.
--
local function check()
  local config_location = vim.fn.stdpath("config")

  local git = "git -C " .. config_location .. " "

  local remote = "origin"
  local branch = "main"
  local remote_branch = remote .. "/" .. branch


  vim.fn.jobstart(git .. "fetch", {
    on_exit = function()
      vim.fn.jobstart(git .. "rev-list --left-right --count " .. remote_branch .. "...HEAD", {
        stdout_buffered = true,
        on_stdout = function(_, data, _)
          local first = data[1]
          local ahead, behind = first:match("^(%d+)%s+(%d+)$")

          if ahead ~= "0" or behind ~= "0" then
            vim.notify("Configuration is out of date. [ ↓ " .. ahead .. " | ↑ " .. behind .. " ]", vim.log.levels.WARN,
              { hide_from_history = true })
          end
        end
      })
    end
  })
end

return {
  check = check
}
