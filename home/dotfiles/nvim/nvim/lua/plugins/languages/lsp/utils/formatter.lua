-- define format utils
-- keymaps are set in lua/plugins/tools/internal/which_key_nvim.lua (M.format())
local M = {}
-- filter function to determine which LSP client should handle formatting
-- prioritizes efm-langserver if available
M.format_filter = function(client, bufnr)
  -- prioritize efm-langserver for formatting
  if client.name == "efm" then
    return true
  end
  -- check if other clients can format and efm is not available
  local has_efm = false
  for _, c in ipairs(vim.lsp.get_clients({ bufnr = bufnr or 0 })) do
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
  -- create a wrapper function that passes both arguments to format_filter
  opts.filter = opts.filter or function(client)
    return M.format_filter(client, opts.bufnr)
  end
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
      -- safe access to filetypes with proper type checking
      if client.config and client.config.settings and client.config.settings.languages then
        -- check if filetype is supported in efm config
        if client.config.settings.languages[filetype] then
          return true
        end
      end
    end
  end
  return false
end
-- format on save for all filetypes
M.setup_format_on_save_all = function()
  local bufnr = vim.api.nvim_get_current_buf()
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  local can_format = false
  for _, client in ipairs(clients) do
    if M.format_filter(client, bufnr) then
      can_format = true
      break
    end
  end
  if can_format then
    M.format_buffer()
  end
end
return M
