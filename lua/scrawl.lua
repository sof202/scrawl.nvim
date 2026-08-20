local plugin_name = "scrawl.nvim"
local plugin_binary_directory = vim.fn.stdpath("data") .. plugin_name .. "/bin/"
local M = {}

-- Locates the location of the scrawl binary. If no binary is found, nil is
-- returned (in which case the caller should initiate a download of scrawl from
-- the statically linked binary)
local function binary_location()
    local binary_name = "scrawl"

    -- Check PATH first
    local on_path = vim.fn.exepath(binary_name)
    if on_path ~= "" then
        return on_path
    end

    -- Check scrawl.nvim's managed binary path
    local binary_path = plugin_binary_directory .. binary_name
    if vim.fn.executable(binary_path) == 1 then
        return binary_path
    end

    -- Caller should now initiate a download
    return nil
end
function M.setup()
    print("hi")
end

return M
