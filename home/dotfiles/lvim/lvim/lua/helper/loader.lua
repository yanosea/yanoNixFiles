local M = {}

-- get all lua files in the directory
M.get_lua_files = function(dir)
  local files = {}
  local dir_files = vim.fn.readdir(dir)

  for _, file in ipairs(dir_files) do
    local full_path = dir .. "/" .. file
    if vim.fn.isdirectory(full_path) == 1 then
      vim.list_extend(files, M.get_lua_files(full_path))
    elseif file:match("%.lua$") then
      table.insert(files, full_path)
    end
  end

  return files
end

-- load all lua files in the directory
M.load_lua_files = function(dir)
  local plugin_files = M.get_lua_files(dir)

  for _, file in ipairs(plugin_files) do
    local relative_path = file:sub(#vim.fn.stdpath("config") + 2, -5):gsub("/", ".")
    local module_path = relative_path:gsub("^lua%.", "")
    if not M.isRequiredModule(module_path) then
      require(module_path)
    end
  end
end

-- return the file have already required or not
M.isRequiredModule = function(file)
  return package.loaded[file] ~= nil
end

return M
