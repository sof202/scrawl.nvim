local plugin_name = "scrawl.nvim"
local scrawl_repo = "sof202/scrawl"
local scrawl_tar = "scrawl-linux-glibc-x86_64.tar.gz"
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

-- Obtains checksum for scrawl tar from GitHub's REST API
--- @param tag string
--- @return string algorithm, string checksum
local function get_checksum(tag)
    local scrawl_api_url = "https://api.github.com/repos/" .. scrawl_repo
    local release_url = scrawl_api_url .. "/releases/tags/" .. tag

    -- 1. Hit GitHub REST API
    if vim.fn.executable("curl") == 0 then
        error("curl is not on PATH. Couldn't download scrawl.")
    end
    local curl_cmd = string.format("curl -sL '%s'", release_url)
    local handle = io.popen(curl_cmd)
    if handle == nil then
        error("Failed to obtain checksum")
    end
    local response = handle:read("*a")
    handle:close()

    -- 2. Extract digest from JSON response
    local algorithm, checksum = response:match('"digest"%s*:%s*"(%w+):(%x+)"')

    if not checksum then
        error("Failed to obtain checksum")
    end

    return algorithm, checksum
end

-- Obtains statically linked binary from GitHub releases and places binary
-- into scrawl.nvim's managed binary path
--- @param tag string
local function download_binary_from_github(tag)
    vim.fn.mkdir(plugin_binary_directory, "p")

    -- Note that only the glibc version is built currently
    local scrawl_repo_url = "https://github.com/" .. scrawl_repo
    local download_url = scrawl_repo_url .. "/releases/download/" .. tag .. "/" .. scrawl_tar

    -- 1. Checksum valiation
    if vim.fn.executable("curl") == 0 then
        error("curl is not on PATH. Couldn't download scrawl.")
    end
    local checksum_curl_cmd = string.format("curl -sL '%s' | sha256sum", download_url)
    local handle = io.popen(checksum_curl_cmd)
    if handle == nil then
        error("curl: Failed to obtain checksum")
    end
    local output = handle:read("*a")
    handle:close()
    local actual_checksum = output:match("^([%x]+)")

    local _, expected_checksum = get_checksum(tag)
    if actual_checksum ~= expected_checksum then
        error(string.format(
            "Checksums do not match (expected %s, actual %s)",
            expected_checksum,
            actual_checksum
        ))
    end

    -- 1. Download
    local download_location = plugin_binary_directory .. scrawl_tar
    vim.notify("Downloading:" .. scrawl_tar, vim.log.levels.INFO)
    local download_curl_cmd = string.format(
        "curl -sL -o '%s' '%s'",
        download_location,
        download_url
    )
    local success, _, _ = os.execute(download_curl_cmd)
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
    if not binary_location() then
        vim.notify("scrawl not found", vim.log.levels.INFO)
        download_binary_from_github("v0.1.2")
    end
end

return M
