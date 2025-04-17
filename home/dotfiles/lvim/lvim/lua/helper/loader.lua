local M = {}

---get all Lua files in the directory recursively
---@param dir string directory path to search
---@return table list of Lua file paths
local function get_lua_files(dir)
  local files = {}
  local cache_key = "lvim_loader_cache_" .. dir:gsub("/", "_")

  -- Try to get from cache first
  local cache = vim.g[cache_key]
  if cache then
    return vim.fn.json_decode(cache)
  end

  -- ensure the directory exists
  if vim.fn.isdirectory(dir) ~= 1 then
    vim.notify("directory not found: " .. dir, vim.log.levels.WARN)
    return files
  end

  local ok, dir_files = pcall(vim.loop.fs_scandir, dir)
  if not ok or not dir_files then
    return files
  end

  local name, type
  while true do
    name, type = vim.loop.fs_scandir_next(dir_files)
    if not name then
      break
    end

    local full_path = dir .. "/" .. name
    if type == "directory" then
      vim.list_extend(files, get_lua_files(full_path))
    elseif name:match("%.lua$") then
      table.insert(files, full_path)
    end
  end

  -- Save to cache
  vim.g[cache_key] = vim.fn.json_encode(files)

  return files
end

---check if a module has already been required
---@param module_name string module name to check
---@return boolean true if the module is already loaded
local function is_required_module(module_name)
  return package.loaded[module_name] ~= nil
end

---load all lua files in the directory
---@param dir string directory path containing Lua files
---@param silent boolean? whether to silence errors (default: false)
---@param exclude_pattern string? pattern to exclude from loading (default: nil)
M.load_lua_files = function(dir, silent, exclude_pattern)
  silent = silent or false
  local plugin_files = get_lua_files(dir)

  -- Sort files to prioritize core configuration
  table.sort(plugin_files, function(a, b)
    -- config files should load first
    if a:match("/config/") and not b:match("/config/") then
      return true
    elseif not a:match("/config/") and b:match("/config/") then
      return false
    end

    -- core should load before user plugins
    if a:match("/core/") and b:match("/user/") then
      return true
    elseif a:match("/user/") and b:match("/core/") then
      return false
    end

    return a < b
  end)

  for _, file in ipairs(plugin_files) do
    -- Skip files matching exclude pattern if provided
    if exclude_pattern and file:match(exclude_pattern) then
      goto continue
    end

    local relative_path = file:sub(#vim.fn.stdpath("config") + 2, -5):gsub("/", ".")
    local module_path = relative_path:gsub("^lua%.", "")

    if not is_required_module(module_path) then
      local ok, err = pcall(require, module_path)
      if not ok and not silent then
        vim.notify("failed to load module: " .. module_path .. "\n" .. err, vim.log.levels.ERROR)
      end
    end

    ::continue::
  end
end

return M
