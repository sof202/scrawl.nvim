local plugin_name = "scrawl.nvim"
local scrawl_repo = "sof202/scrawl"
local scrawl_tar = "scrawl-linux-glibc-x86_64.tar.gz"
local scrawl_repo_url = "https://github.com/" .. scrawl_repo
local scrawl_api_url = "https://api.github.com/repos/" .. scrawl_repo
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

-- Both tar and curl are required to download the scrawl binary from the GitHub
-- releases page
local function check_download_dependencies()
    if vim.fn.executable("curl") == 0 then
        error("curl is not on PATH. Couldn't download scrawl.")
    end
    if vim.fn.executable("tar") == 0 then
        error("tar is not on PATH. Couldn't extract scrawl.")
    end
end

-- Runs a system command and returns stdout, or errors with a message combining
-- the given label and the command's stderr/exit code
--- @param cmd string[]
--- @param label string
--- @return string stdout
local function run(cmd, label)
    local result = vim.fn.system(cmd)
    if vim.v.shell_error ~= 0 then
        error(string.format("%s (exit %d): %s", label, vim.v.shell_error, result))
    end
    return result
end

-- Use GitHub's REST API to obtain the most recent tag
--- @return string tag
local function get_latest_tag()
    local releases_url = scrawl_api_url .. "/releases/latest"
    local response = run(
        { "curl", "-sL", releases_url },
        "Failed to fetch latest release"
    )
    local tag = response:match('"tag_name"%s*:%s*"(v%d+%.%d+%.%d+)"')
    if not tag then
        error("Failed to find tag_name in latest release response")
    end
    return tag
end

-- Obtains checksum for scrawl tar from GitHub's REST API
--- @param tag string
--- @return string algorithm, string checksum
local function get_checksum(tag)
    local tag_url = scrawl_api_url .. "/releases/tags/" .. tag
    local response = run(
        { "curl", "-sL", tag_url },
        "Failed to fetch release info for " .. tag
    )
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
    check_download_dependencies()
    vim.fn.mkdir(plugin_binary_directory, "p")

    -- Note that only the glibc version is built currently
    local download_url = scrawl_repo_url .. "/releases/download/" .. tag .. "/" .. scrawl_tar
    local download_location = plugin_binary_directory .. scrawl_tar

    -- 1. Download
    vim.notify("Downloading:" .. scrawl_tar, vim.log.levels.INFO)
    run(
        { "curl", "-sL", "-o", download_location, download_url },
        "Failed to download tar from " .. download_url
    )

    -- 2. Compare hashes
    local checksum_output = run(
        { "sha256sum", download_location },
        "Failed to compute checksum on: " .. download_location
    )
    local actual_checksum = checksum_output:match("^(%x+)")
    local expected_checksum = get_checksum(tag)
    if actual_checksum ~= expected_checksum then
        os.remove(download_location)
        error(string.format(
            "Checksums do not match (expected %s, actual %s)",
            expected_checksum,
            actual_checksum
        ))
    end

    -- 3. Extract
    run(
        { "tar", "-C", plugin_binary_directory, "-xzf", download_location },
        "Failed to extract " .. download_location
    )

    -- 4. Move files
    local extracted_directory = download_location:gsub("%.tar%.gz$", "")
    local files = vim.fn.globpath(extracted_directory, "*", false, true)
    for _, file in ipairs(files) do
        local filename = vim.fn.fnamemodify(file, ":t")
        local new_path = plugin_binary_directory .. filename
        if vim.fn.isdirectory(file) == 0 then
            os.rename(file, new_path)
        end
    end

    -- 4. Remove tar and directory
    os.remove(download_location)
    vim.fn.delete(extracted_directory, "rf")
    vim.notify("Installed scrawl.", vim.log.levels.INFO)
end

function M.setup()
    if not binary_location() then
        vim.notify("scrawl not found", vim.log.levels.INFO)
        local ok, err = pcall(download_binary_from_github, get_latest_tag())
        if not ok then
            vim.notify("scrawl.nvim: " .. tostring(err), vim.log.levels.ERROR)
        end
    end
end

return M
