local download = require("scrawl.download")
local paths = require("scrawl.paths")

local M = {}

function M.setup()
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

    vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        callback = function()
            local markdown = require("scrawl.markdown")
            -- mi -> markdown insert
            vim.keymap.set("n", "<leader>mi", function()
                local binary = paths.binary_location()
                if binary then
                    markdown.execute_scrawl(binary)
                end
            end, { buffer = true, noremap = true, silent = true })
        end,
    })
end

return M
