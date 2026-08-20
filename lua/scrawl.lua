local plugin_name = "scrawl.nvim"
local scrawl_repo = "sof202/scrawl"
local plugin_binary_directory = vim.fn.stdpath("data") .. "/" .. plugin_name .. "/bin/"
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

-- Obtains statically linked binary from GitHub releases and places binary
-- into scrawl.nvim's managed binary path
--- @param tag string
local function download_binary_from_github(tag)
    print(plugin_binary_directory)
    vim.fn.mkdir(plugin_binary_directory, "p")

    -- Note that only the glibc version is built currently
    local scrawl_repo_url = "https://github.com/" .. scrawl_repo
    local tar_name = "scrawl-linux-glibc-x86_64.tar.gz"
    local download_url = scrawl_repo_url .. "/releases/download/" .. tag .. "/" .. tar_name

    -- 1. Download
    if vim.fn.executable("curl") == 0 then
        error("curl is not on PATH. Couldn't download scrawl.")
    end

    download_location = plugin_binary_directory .. tar_name
    vim.notify("Downloading:" .. tar_name, vim.log.levels.INFO)
    local curl_cmd = string.format(
        "curl -sL -o '%s' '%s'",
        download_location,
        download_url
    )
    local success, exit_code, _ = os.execute(curl_cmd)
    if not success then
        error("curl failed to download tar from " .. download_url)
    end

    -- 2. Extract
    if vim.fn.executable("tar") == 0 then
        error("tar is not on PATH. Couldn't extract scrawl.")
    end

    local tar_cmd = string.format(
        "tar -C '%s' -xzf '%s'",
        plugin_binary_directory,
        download_location
    )
    os.execute(tar_cmd)

    -- 3. Move files
    local extracted_directory = download_location.gsub(
        download_location,
        ".tar.gz",
        ""
    )
    local files = vim.fn.globpath(extracted_directory, "*", false, true)
    for _, file in ipairs(files) do
        local filename = vim.fn.fnamemodify(file, ":t")
        local new_path = plugin_binary_directory .. "/" .. filename
        if vim.fn.isdirectory(file) == 0 then
            os.rename(file, new_path)
        end
    end

    -- 4. Remove tar and directory
    os.remove(download_location)
    os.remove(extracted_directory)

    vim.notify("Installed scrawl.", vim.log.levels.INFO)
end

function M.setup()
    print("hi")
end

return M
