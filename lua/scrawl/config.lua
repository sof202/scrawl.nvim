local M = {}

M.defaults = {
    keymaps = {
        markdown_insert = "<leader>mi"
    },
    window_opts = {
        height = nil,
        width = nil,
    },
    markdown_opts = {
        height = 300,
        width = 300,
    },
}

M.opts = {}

function M.setup(user_opts)
    M.opts = vim.tbl_deep_extend("force", M.defaults, user_opts or {})
end

return M
