local download = require("scrawl.download")
local paths = require("scrawl.paths")

local M = {}

function M.setup(user_opts)
    if not paths.binary_location() then
        vim.notify("scrawl not found", vim.log.levels.INFO)
        local ok, err = pcall(
            download.download_binary_from_github,
            paths.plugin_binary_directory,
            download.get_latest_tag()
        )
        if not ok then
            vim.notify("scrawl.nvim: " .. tostring(err), vim.log.levels.ERROR)
            return
        end
    end

    require("scrawl.config").setup(user_opts)
    require("scrawl.markdown").setup()
end

return M
