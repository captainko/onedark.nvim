local M = {}

M.styles_list = { 'dark', 'darker', 'cool', 'deep', 'warm', 'warmer', 'light' }

---Change onedark option (vim.g.onedark_config.option)
---It can't be changed directly by modifing that field due to a Neovim lua bug with global variables (onedark_config is a global variable)
---@param opt string: option name
---@param value any: new value
function M.set_options(opt, value)
    local cfg = vim.g.onedark_config
    cfg[opt] = value
    vim.g.onedark_config = cfg
end

---Apply the colorscheme (same as ':colorscheme onedark')
function M.colorscheme()
    vim.cmd("hi clear")
    if vim.fn.exists("syntax_on") then vim.cmd("syntax reset") end
    vim.o.termguicolors = true
    vim.g.colors_name = "onedark"
    if vim.o.background == 'light' then
        M.set_options('style', 'light')
    elseif vim.g.onedark_config.style == 'light' then
        M.set_options('style', 'dark')
    end
    require('onedark.highlights').setup()
    require('onedark.terminal').setup()
end

---Toggle between onedark styles
function M.toggle()
    local index = vim.g.onedark_config.toggle_style_index + 1
    if index > #vim.g.onedark_config.toggle_style_list then index = 1 end
    M.set_options('style', vim.g.onedark_config.toggle_style_list[index])
    M.set_options('toggle_style_index', index)
    if vim.g.onedark_config.style == 'light' then
        vim.o.background = 'light'
    else
        vim.o.background = 'dark'
    end
    vim.api.nvim_command('colorscheme onedark')
end

local default_config = {
    -- Main options --
    style = 'dark',    -- choose between 'dark', 'darker', 'cool', 'deep', 'warm', 'warmer' and 'light'
    toggle_style_key = '<leader>ts',
    toggle_style_list = M.styles_list,
    transparent = false,     -- don't set background
    term_colors = true,      -- if true enable the terminal
    ending_tildes = false,    -- show the end-of-buffer tildes

    -- Changing Formats --
    code_style = {
        comments = 'italic',
        keywords = 'none',
        functions = 'none',
        strings = 'none',
        variables = 'none'
    },

    -- Custom Highlights --
    colors = {}, -- Override default colors
    highlights = {}, -- Override highlight groups

    -- Plugins Related --
    diagnostics = {
        darker = true, -- darker colors for diagnostic
        undercurl = true,   -- use undercurl for diagnostics
        background = true,    -- use background color for virtual text
    },
}

---Setup onedark.nvim options, without applying colorscheme
---@param opts table: a table containing options
function M.setup(opts)
    if not vim.g.onedark_config or not vim.g.onedark_config.loaded then    -- if it's the first time setup() is called
        vim.g.onedark_config = vim.tbl_deep_extend('keep', vim.g.onedark_config or {}, default_config)
        local old_config = require('onedark.old_config')
        if old_config then opts = old_config end
        M.set_options('loaded', true)
        M.set_options('toggle_style_index', 0)
    end
    if opts then
        vim.g.onedark_config = vim.tbl_deep_extend('force', vim.g.onedark_config, opts)
        if opts.toggle_style_list then    -- this table cannot be extended, it has to be replaced
            M.set_options('toggle_style_list', opts.toggle_style_list)
        end
        if opts.highlights then    -- user custom highlights
            local colors = require('onedark.colors')
            local function replace_color(color_name)
                if not color_name then return nil end
                if color_name:sub(1, 1) ~= '$' then return color_name end
                local name = color_name:sub(2, -1)
                if not colors[name] then
                    vim.schedule(function()
                        vim.notify('onedark.nvim: unknown color "' .. name .. '"', vim.log.levels.ERROR, { title = "onedark.nvim" })
                    end)
                end
                return colors[name]
            end

            for group_name, group_settings in pairs(opts.highlights) do
                group_settings.fg = replace_color(group_settings.fg)
                group_settings.bg = replace_color(group_settings.bg)
                group_settings.sp = replace_color(group_settings.sp)
                opts.highlights[group_name] = group_settings
            end
            M.set_options('highlights', opts.highlights)
        end
    end
    vim.api.nvim_set_keymap('n', vim.g.onedark_config.toggle_style_key, '<cmd>lua require("onedark").toggle()<cr>', { noremap = true, silent = true })
end

function M.load()
  vim.api.nvim_command('colorscheme onedark')
end

return M
