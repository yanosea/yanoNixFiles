local M = {}
function M.setup(servers)
  local servers_config_path = "plugins.languages.lsp.servers"
  for _, server in ipairs(servers) do
    local ok, server_config = pcall(require, servers_config_path .. "." .. server:gsub("-", "_"))
    if ok then
      server_config.setup()
    else
      vim.lsp.config(server, {})
    end
  end
end
return M
