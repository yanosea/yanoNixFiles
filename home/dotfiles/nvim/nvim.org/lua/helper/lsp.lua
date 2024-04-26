local function enable_autoformat()
  local root = vim.fn.getcwd(0)
  local disable_projects = vim.split(os.getenv("NVIM_DISABLE_AUTOFORMATTING_PROJECTS") or "", ",")

  for _, project in ipairs(disable_projects) do
    if root == project then
      return false
    end
  end

  return true
end

local common_on_attach = function(client, _)
  client.server_capabilities.semanticTokensProvider = nil
end

local enable_fmt_on_attach = function(client, bufnr)
  common_on_attach(client, bufnr)

  if client.supports_method("textDocument/formatting") and enable_autoformat() then
    local augLspFormatting = vim.api.nvim_create_augroup("LspFormatting", { clear = false })
    vim.api.nvim_clear_autocmds({ group = augLspFormatting, buffer = bufnr })
    vim.api.nvim_create_autocmd("BufWritePre", {
      callback = function()
        vim.lsp.buf.format({ bufnr = bufnr, timeout_ms = 5000 })
      end,
      group = augLspFormatting,
      buffer = bufnr,
    })
  end
end

local disable_fmt_on_attach = function(client, bufnr)
  common_on_attach(client, bufnr)
  client.server_capabilities.documentFormattingProvider = false
end

return {
  enable_fmt_on_attach = enable_fmt_on_attach,
  disable_fmt_on_attach = disable_fmt_on_attach,
}
