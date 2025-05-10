local themes = {
  ["kanagawa-dragon"] = require("themes.kanagawa-dragon"),
  ["oldworld"] = require("themes.oldworld")
}

local current_hour = tonumber(os.date("%H"));

if current_hour >= 6 and current_hour < 19 then
  return themes["oldworld"]
else
  return themes["kanagawa-dragon"]
end
