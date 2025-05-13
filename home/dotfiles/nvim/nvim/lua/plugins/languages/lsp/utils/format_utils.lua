-- define format utils
-- keymaps are set in lua/plugins/tools/internal/which_key_nvim.lua (M.format())
local M = {}
-- filter function to determine which LSP client should handle formatting
-- prioritizes efm-langserver if available
M.format_filter = function(client)
  -- prioritize efm-langserver for formatting
  if client.name == "efm" then
    return true
  end
  -- check if other clients can format and efm is not available
  local has_efm = false
  for _, c in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    if c.name == "efm" then
      has_efm = true
      break
    end
  end
  -- if efm is not available, fallback to other clients with formatting capability
  if not has_efm and client.supports_method("textDocument/formatting") then
    return true
  end
  return false
end
-- simple wrapper for vim.lsp.buf.format() to provide defaults
M.format = function(opts)
  opts = opts or {}
  opts.filter = opts.filter or M.format_filter
  return vim.lsp.buf.format(opts)
end
-- format current buffer or visual selection with LSP
M.format_buffer = function()
  M.format({
    bufnr = vim.api.nvim_get_current_buf(),
    async = false,
  })
end
-- setup format on save for specific filetypes
M.setup_format_on_save = function(filetypes)
  local group = vim.api.nvim_create_augroup("FormatOnSave", { clear = true })
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = group,
    callback = function()
      local current_ft = vim.bo.filetype
      for _, ft in ipairs(filetypes) do
        if current_ft == ft then
          M.format_buffer()
          break
        end
      end
    end,
  })
  return group
end
-- check if efm-langserver is configured for the current filetype
M.has_efm_formatter = function(filetype)
  filetype = filetype or vim.bo.filetype
  local clients = vim.lsp.get_clients({ bufnr = 0 })

  for _, client in ipairs(clients) do
    if client.name == "efm" then
      if client.config and client.config.filetypes then
        for _, ft in ipairs(client.config.filetypes) do
          if ft == filetype then
            return true
          end
        end
      end
    end
  end
  return false
end
-- log formatting information for debugging
M.log_format_info = function()
  local filetype = vim.bo.filetype
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  local info = {
    filetype = filetype,
    clients = {},
    has_efm = false,
  }
  for _, client in ipairs(clients) do
    local client_info = {
      name = client.name,
      supports_formatting = client.supports_method("textDocument/formatting"),
      filetypes = client.config and client.config.filetypes or {},
    }
    table.insert(info.clients, client_info)
    -- check if efm-langserver is available
    if client.name == "efm" then
      info.has_efm = true
    end
  end
  vim.notify(vim.inspect(info), vim.log.levels.INFO, {
    title = "Format Info",
    timeout = 5000,
  })
end
return M
