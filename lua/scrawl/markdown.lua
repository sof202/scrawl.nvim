local M = {}

--- @param binary_location string
local function execute_scrawl(binary_location)
    -- Ensures that user cannot put some other type of file extension (scrawl
    -- explicitly makes png files). It also means it is quicker to type out the
    -- image name for the user.
    local picture_path = vim.fn.input("Picture path: ")
    local picture_path_no_ext = vim.fn.fnamemodify(picture_path, ":r")

    picture_path = picture_path_no_ext .. ".png"

    -- Ensure that the path where the picture will be placed exists
    local picture_dir = vim.fn.expand("%:h") .. "/" .. vim.fn.fnamemodify(picture_path, ":h")
    vim.fn.mkdir(picture_dir, "p")

    local alt_text = vim.fn.fnamemodify(picture_path, ":t")

    vim.fn.system({ binary_location, picture_path })

    -- Pressing ESC in scrawl results in no image being saved
    if vim.fn.exists(picture_path) == 1 then
        vim.api.nvim_paste(
            string.format("![%s](%s)", alt_text, picture_path),
            false,
            -1
        )
    end
end

function M.setup()
    local config = require("scrawl.config")
    local paths = require("scrawl.paths")

    vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        callback = function()
            local keymap = config.opts.keymaps.markdown_insert
            if not keymap then
                return -- disabled for whatever reason
            end
            vim.keymap.set("n", keymap, function()
                local binary = paths.binary_location()
                if binary then
                    execute_scrawl(binary)
                end
            end, { buffer = true, noremap = true, silent = true })
        end,
    })
end

return M
