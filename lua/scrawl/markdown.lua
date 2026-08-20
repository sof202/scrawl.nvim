local M = {}

function M.execute_scrawl()
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

    vim.fn.system({ "scrawl", picture_path })
    vim.api.nvim_paste(
        string.format("![%s](%s)", alt_text, picture_path),
        false,
        -1
    )
end

return M
