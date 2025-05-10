return function()
    vim.g.theme_choices = {
        [[colorscheme oldworld]],
        [[colorscheme kanagawa-dragon]],
        [[colorscheme duskfox]],
        [[colorscheme tokyodark]],
        [[colorscheme vague]],
    };

    local current_hour = tonumber(os.date("%H"));

    -- if current_hour >= 6 and current_hour < 19 then
    --   vim.cmd [[ colorscheme tokyodark ]]
    -- else
    vim.cmd [[ colorscheme kanagawa-dragon ]]
    -- end
end
