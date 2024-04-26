local signs = {
  Error = " ",
  Warn = " ",
  Hint = " ",
  Info = " ",
}

for type, icon in pairs(signs) do
  local hl = "DiagnosticSign" .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

local fs = require("helper.fs")
local lsp = require("helper.lsp")

local efm_opts = function()
  local rootMarkers = {
    prettier = {
      ".prettierrc",
      ".prettierrc.js",
      ".prettierrc.mjs",
      ".prettierrc.cjs",
      ".prettierrc.yml",
      ".prettierrc.yaml",
      ".prettierrc.json",
      ".prettierrc.json5",
      ".prettierrc.toml",
    },
    deno = {
      "deno.json",
      "deno.jsonc",
    },
    stylua = {
      "stylua.toml",
      ".stylua.toml",
    },
    textlint = {
      ".textlintrc",
      ".textlintrc.yml",
      ".textlintrc.yaml",
      ".textlintrc.json",
    },
    eslint = {
      ".eslintrc.js",
      ".eslintrc.yml",
      ".eslintrc.yaml",
      ".eslintrc.json",
      "eslint.config.js",
    },
  }

  local prettier = {
    formatCommand = "node_modules/.bin/prettier --stdin --stdin-filepath ${INPUT}",
    formatStdin = true,
    rootMarkers = rootMarkers.prettier,
  }

  local denofmt = {
    formatCommand = "deno fmt --ext ${FILEEXT} -",
    formatStdin = true,
  }

  local denofmt_or_prettier = fs.has_file(rootMarkers.prettier) and prettier or denofmt

  local stylua = {
    formatCommand = "stylua --color Never -",
    formatStdin = true,
    rootMarkers = rootMarkers.stylua,
  }

  local textlint = {
    lintCommand = "node_modules/.bin/textlint --no-color --format compact --stdin --stdin-filename ${INPUT}",
    lintStdin = true,
    lintFormats = {
      "%.%#: line %l, col %c, %trror - %m",
      "%.%#: line %l, col %c, %tarning - %m",
    },
    rootMarkers = rootMarkers.textlint,
  }

  local eslint = {
    lintCommand = "node_modules/.bin/eslint -f visualstudio --stdin --stdin-filename ${INPUT}",
    lintIgnoreExitCode = true,
    lintStdin = true,
    lintFormats = {
      "%f(%l,%c): %tarning %m",
      "%f(%l,%c): %rror %m",
    },
    rootMarkers = rootMarkers.eslint,
    commands = {
      {
        title = "eslint fix",
        commands = "node_modules/.bin/eslint",
        arguments = { "--fix", "${INPUT}" },
      },
    },
  }

  local languages = {
    html = { prettier },
    css = { prettier },
    scss = { prettier },
    javascript = { denofmt_or_prettier, eslint },
    javascriptreact = { denofmt_or_prettier, eslint },
    typescript = { denofmt_or_prettier, eslint },
    typescriptreact = { denofmt_or_prettier, eslint },
    json = { denofmt_or_prettier },
    jsonc = { denofmt_or_prettier },
    yaml = { prettier },
    markdown = { denofmt_or_prettier, textlint },
    lua = { stylua },
  }

  if vim.fn.executable("cspell") then
    languages["="] = {
      {
        lintCommand = "cspell --no-progress --no-summary --no-color --config=~/.config/cspell/cspell.json ${INPUT}",
        lintIgnoreExitCode = true,
        lintFormats = {
          "%f:%l:%c - %m",
          "%f:%l:%c %m",
        },
        lintSeverity = 4,
      },
    }
  end

  return {
    init_options = {
      documentFormatting = true,
      hover = true,
      codeAction = true,
    },
    filetypes = vim.tbl_keys(languages),
    settings = { languages = languages },
  }
end

return {
  {
    -- https://github.com/neovim/nvim-lspconfig
    "neovim/nvim-lspconfig",
    lazy = true,
    event = "BufReadPre",
    dependencies = {
      -- https://github.com/williamboman/mason.nvim
      "williamboman/mason.nvim",
      -- https://github.com/williamboman/mason-lspconfig.nvim
      "williamboman/mason-lspconfig.nvim",
      -- https://github.com/Shougo/ddc-source-lsp
      "Shougo/ddc-source-lsp",
    },
    config = function()
      require("lspconfig.ui.windows").default_options.border = "single"
      vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "single" })
      vim.diagnostic.config({ float = { border = "single" } })

      require("mason").setup()
      require("mason-lspconfig").setup()

      local lspconfig = require("lspconfig")
      local ddc_source_lsp = require("ddc_source_lsp")

      require("mason-lspconfig").setup_handlers({
        function(server)
          local buf_full_filename = vim.api.nvim_buf_get_name(0)

          local opts = {
            capabilities = ddc_source_lsp.make_client_capabilities(),
            on_attach = lsp.enable_fmt_on_attach,
          }

          if server == "denols" then
            local deno_root_dir = lspconfig.util.root_pattern("deno.json", "deno.jsonc")
            if deno_root_dir(buf_full_filename) == nil then
              return
            end
            opts.root_dir = deno_root_dir
            opts.cmd = { "deno", "lsp", "--unstable" }
            opts.init_options = { lint = true, unstable = true }
            opts.on_attach = lsp.disable_fmt_on_attach
          elseif server == "tsserver" then
            local node_root_dir = lspconfig.util.root_pattern("package.json")
            if node_root_dir(buf_full_filename) == nil then
              return
            end
            opts.root_dir = node_root_dir
            opts.on_attach = lsp.disable_fmt_on_attach
          elseif server == "tailwindcss" then
            local tailwind_root_dir = lspconfig.util.root_pattern("tailwind.config.{js,cjs,ts}", "twind.config.{js,ts}")
            if tailwind_root_dir(buf_full_filename) == nil then
              return
            end
            opts.root_dir = tailwind_root_dir
          elseif server == "cssls" then
            opts.filetypes = { "css", "scss", "sass", "less" }
          elseif server == "yamlls" then
            opts.settings = {
              yaml = {
                keyOrdering = false,
              },
            }
          elseif server == "efm" then
            opts = vim.tbl_deep_extend("force", opts, efm_opts())
          elseif server == "html" or server == "jsonls" or server == "lua_ls" then
            opts.on_attach = lsp.disable_fmt_on_attach
          end

          lspconfig[server].setup(opts)
        end,
      })

      vim.keymap.set("n", "gE", "<CMD>Ddu lsp_diagnostic -unique<CR>", { desc = "Lists all the diagnostics" })
      vim.keymap.set("n", "ge", "<CMD>lua vim.diagnostic.open_float()<CR>", { desc = "Show diagnostic" })
      vim.keymap.set("n", "]g", "<CMD>lua vim.diagnostic.goto_next()<CR>", { desc = "Go to next diagnostic" })
      vim.keymap.set("n", "[g", "<CMD>lua vim.diagnostic.goto_prev()<CR>", { desc = "Go to previous diagnostic" })

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function()
          vim.keymap.set("n", "K", "<CMD>lua vim.lsp.buf.hover()<CR>", { desc = "Show hover" })
          vim.keymap.set("n", "gf", "<CMD>lua vim.lsp.buf.format({ async = true })<CR>", { desc = "Formatting" })
          vim.keymap.set("n", "gn", "<CMD>lua vim.lsp.buf.rename()<CR>", { desc = "Rename definition" })
          vim.keymap.set("n", "ga", "<CMD>Ddu lsp_codeAction -unique<CR>", { desc = "Show available code actions" })
          vim.keymap.set("n", "gd", "<CMD>Ddu lsp_definition<CR>", { desc = "Lists all the definition" })
          vim.keymap.set("n", "gr", "<CMD>Ddu lsp_references -unique<CR>", { desc = "Lists all the references" })
        end,
      })
    end,
  },
}
