-- LSP ユーティリティ関数
local M = {}

-- Neovim ランタイムディレクトリを取得
M.get_nvim_runtime_dir = function()
  return vim.fn.expand "$VIMRUNTIME"
end

-- 設定ディレクトリを取得
M.get_config_dir = function()
  return vim.fn.stdpath "config"
end

-- コマンドのフルパスを解決
M.resolve_full_path = function(cmd)
  if not cmd or cmd == "" then
    return cmd
  end
  if cmd:sub(1, 1) == "/" then
    return cmd
  end
  local handle = io.popen("which " .. cmd .. " 2>/dev/null")
  if handle then
    local result = handle:read("*a"):gsub("%s+$", "")
    handle:close()
    if result ~= "" then
      return result
    end
  end
  local paths = vim.split(vim.fn.getenv("PATH"), ":")
  for _, path in ipairs(paths) do
    local full_path = path .. "/" .. cmd
    if vim.fn.executable(full_path) == 1 then
      return full_path
    end
  end

  return cmd
end

-- ワークスペースにパッケージを追加
M.add_packages_to_workspace = function(packages, config)
  config.settings = config.settings or {}
  config.settings.Lua = config.settings.Lua or {}
  config.settings.Lua.workspace = config.settings.Lua.workspace or {}
  config.settings.Lua.workspace.library = config.settings.Lua.workspace.library or {}
  local ok, runtimedirs = pcall(function()
    return vim.api.nvim__get_runtime({ "lua" }, true, { is_lua = true }) or {}
  end)
  if not ok or type(runtimedirs) ~= "table" then
    runtimedirs = {}
  end
  local workspace_lib = config.settings.Lua.workspace.library
  for _, v in pairs(runtimedirs) do
    for _, pack in ipairs(packages) do
      if v:match(pack) and not vim.tbl_contains(workspace_lib, v) then
        table.insert(workspace_lib, v)
      end
    end
  end
end

-- デフォルトのLuaワークスペース設定
M.default_workspace = {
  library = {
    M.get_nvim_runtime_dir(),
    M.get_config_dir(),
    require("neodev.config").types(),
    "${3rd}/busted/library",
    "${3rd}/luassert/library",
    "${3rd}/luv/library",
  },
  maxPreload = 5000,
  preloadFileSize = 10000,
}

return M
