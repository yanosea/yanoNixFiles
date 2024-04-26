return {
  {
    -- https://github.com/Shougo/ddu.vim
    "Shougo/ddu.vim",
    lazy = false,
    enabled = true,
    dependencies = {
      -- https://github.com/vim-denops/denops.vim
      "vim-denops/denops.vim",
      -- ui
      -- https://github.com/Shougo/ddu-ui-filer
      "Shougo/ddu-ui-filer",
      -- https://github.com/Shougo/ddu-ui-ff
      "Shougo/ddu-ui-ff",
      -- source
      -- https://github.com/Shougo/ddu-source-action
      "Shougo/ddu-source-action",
      -- https://github.com/Shougo/ddu-source-file
      "Shougo/ddu-source-file",
      -- https://github.com/Shougo/ddu-source-file_old
      "Shougo/ddu-source-file_old",
      -- https://github.com/matsui54/ddu-source-file_external
      "matsui54/ddu-source-file_external",
      -- https://github.com/shun/ddu-source-rg
      "shun/ddu-source-rg",
      -- https://github.com/shun/ddu-source-buffer
      "shun/ddu-source-buffer",
      -- https://github.com/matsui54/ddu-source-help
      "matsui54/ddu-source-help",
      -- https://github.com/uga-rosa/ddu-source-lsp
      "uga-rosa/ddu-source-lsp",
      -- https://github.com/kyoh86/ddu-source-quickfix_history
      "kyoh86/ddu-source-quickfix_history",
      -- https://github.com/Omochice/ddu-source-anyjump
      "Omochice/ddu-source-anyjump",
      -- filter
      -- https://github.com/Shougo/ddu-filter-sorter_alpha
      "Shougo/ddu-filter-sorter_alpha",
      -- https://github.com/Shougo/ddu-filter-matcher_substring
      "Shougo/ddu-filter-matcher_substring",
      -- Kind
      -- https://github.com/Shougo/ddu-kind-file
      "Shougo/ddu-kind-file",
      -- https://github.com/Shougo/ddu-kind-word
      "Shougo/ddu-kind-word",
      -- column
      -- https://github.com/ryota2357/ddu-column-icon_filename
      "ryota2357/ddu-column-icon_filename",
      -- ui-select
      -- https://github.com/matsui54/ddu-vim-ui-select
      "matsui54/ddu-vim-ui-select",
      -- command
      -- https://github.com/Shougo/ddu-commands.vim
      "Shougo/ddu-commands.vim",
    },
    init = function()
      vim.keymap.set("n", ";f", "<CMD>Ddu file_external<CR>")
      vim.keymap.set("n", ";h", "<CMD>Ddu help<CR>")
      vim.keymap.set("n", ";B", "<CMD>Ddu buffer<CR>")
      vim.keymap.set("n", ";o", "<CMD>Ddu file_old<CR>")
      vim.keymap.set("n", ";g", "<CMD>Ddu -name=grep<CR>")
      vim.keymap.set("n", ";b", [[<CMD>Ddu -name=filer -searchPath=`expand('%:p')`<CR>]])
      vim.keymap.set("n", ";q", "<CMD>Ddu quickfix_history<CR>")
      vim.keymap.set("n", "gD", "<CMD>Ddu anyjump_definition -ui=ff<CR>")
      vim.keymap.set("n", "gR", "<CMD>Ddu anyjump_reference -ui=ff<CR>")
    end,
    config = function()
      local reset_ui = function()
        local top = 4
        local width = vim.opt.columns:get()
        local height = vim.opt.lines:get()
        local win_width = math.floor(width * 0.8)
        local win_height = math.floor(height * 0.4)

        vim.fn["ddu#custom#patch_global"]({
          ui = "ff",
          uiParams = {
            _ = {
              winWidth = win_width,
              winHeight = win_height,
              winCol = math.floor((width - win_width) / 2),
              winRow = top,
              split = "floating",
              floatingBorder = "single",
              preview = true,
              previewFloating = true,
              previewFloatingBorder = "single",
              previewSplit = "vertical",
              previewWidth = math.floor(win_width * 0.5),
              previewHeight = win_height - 2,
              previewCol = math.floor(width / 2) - 2,
              previewRow = top + 1,
            },
            ff = {
              filterSplitDirection = "floating",
              filterFloatingPosition = "top",
              autoResize = false,
              ignoreEmpty = false,
            },
            filer = {},
          },
        })
      end

      reset_ui()

      vim.api.nvim_create_autocmd("VimResized", {
        pattern = "*",
        callback = reset_ui,
      })

      vim.fn["ddu#custom#patch_global"]({
        sourceParams = {
          anyjump_definition = {
            highlights = {
              path = "Normal",
              lineNr = "Normal",
              word = "Title",
            },
            removeCommentsFromResults = true,
          },
          anyjump_reference = {
            highlights = {
              path = "Normal",
              lineNr = "Normal",
              word = "Title",
            },
            removeCommentsFromResults = true,
            onlyCurrentFiletype = false,
          },
          file_external = {
            cmd = { "fd", ".", "-H", "-E", ".git", "-t", "f" },
          },
          rg = {
            inputType = "regex",
            args = { "--json", "--column", "--no-heading", "--color", "never", "--hidden", "--glob", "!.git" },
          },
        },
        sourceOptions = {
          _ = {
            ignoreCase = true,
            matchers = { "matcher_substring" },
          },
        },
        filterParams = {
          matcher_substring = {
            highlightMatched = "Search",
          },
        },
        kindOptions = {
          file = {
            defaultAction = "open",
          },
          lsp = {
            defaultAction = "open",
          },
          help = {
            defaultAction = "open",
          },
          action = {
            defaultAction = "do",
          },
          word = {
            defaultAction = "append",
          },
          ui_select = {
            defaultAction = "select",
          },
          lsp_codeAction = {
            defaultAction = "apply",
          },
          quickfix_history = {
            defaultAction = "open",
          },
        },
      })

      -- live grep
      vim.fn["ddu#custom#patch_local"]("grep", {
        sources = {
          { name = "rg" },
        },
        sourceOptions = {
          rg = {
            matchers = {},
            volatile = true,
          },
        },
      })

      -- filer
      vim.fn["ddu#custom#patch_local"]("filer", {
        ui = "filer",
        sync = true,
        sources = {
          { name = "file" },
        },
        sourceOptions = {
          _ = {
            sorters = { "sorter_alpha" },
            columns = { "icon_filename" },
          },
        },
        actionOptions = {
          narrow = {
            quit = false,
          },
        },
      })

      local opts = { buffer = true, silent = true, noremap = true }
      local nowait = { buffer = true, silent = true, noremap = true, nowait = true }

      local common_keymaps = function()
        vim.wo.cursorline = true
        vim.keymap.set("n", "<CR>", '<CMD>call ddu#ui#do_action("itemAction")<CR>', opts)
        vim.keymap.set(
          "n",
          "os",
          '<CMD>call ddu#ui#do_action("itemAction", {"name": "open", "params": {"command": "split"}})<CR>',
          opts
        )
        vim.keymap.set(
          "n",
          "ov",
          '<CMD>call ddu#ui#do_action("itemAction", {"name": "open", "params": {"command": "vsplit"}})<CR>',
          opts
        )
        vim.keymap.set("n", "<SPACE>", '<CMD>call ddu#ui#do_action("toggleSelectItem")<CR>', opts)
        vim.keymap.set("n", "<ESC>", '<CMD>call ddu#ui#do_action("quit")<CR>', nowait)
        vim.keymap.set("n", "q", '<CMD>call ddu#ui#do_action("quit")<CR>', nowait)
        vim.keymap.set("n", "a", '<CMD>call ddu#ui#do_action("chooseAction")<CR>', opts)
      end

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "ddu-filer",
        callback = function()
          common_keymaps()
          vim.keymap.set("n", "y", '<CMD>call ddu#ui#do_action("itemAction", {"name": "copy"})<CR>', opts)
          vim.keymap.set("n", "p", '<CMD>call ddu#ui#do_action("itemAction", {"name": "paste"})<CR>', opts)
          vim.keymap.set("n", "d", '<CMD>call ddu#ui#do_action("itemAction", {"name": "delete"})<CR>', opts)
          vim.keymap.set("n", "r", '<CMD>call ddu#ui#do_action("itemAction", {"name": "rename"})<CR>', opts)
          vim.keymap.set("n", "m", '<CMD>call ddu#ui#do_action("itemAction", {"name": "move"})<CR>', opts)
          vim.keymap.set("n", "c", '<CMD>call ddu#ui#do_action("itemAction", {"name": "newFile"})<CR>', opts)
          vim.keymap.set("n", "C", '<CMD>call ddu#ui#do_action("itemAction", {"name": "newDirectory"})<CR>', opts)
          vim.cmd([[nnoremap <buffer><expr> <Tab>
             \ ddu#ui#get_item()->get('isTree', v:false)
             \ ? "<CMD>call ddu#ui#do_action('expandItem', {'mode': 'toggle'})<CR>"
             \ : "<Tab>"]])
          vim.cmd([[nnoremap <buffer><expr> <CR>
             \ ddu#ui#get_item()->get('isTree', v:false)
             \ ? "<CMD>call ddu#ui#do_action('expandItem', {'mode': 'toggle'})<CR>"
             \ : "<CMD>call ddu#ui#do_action('itemAction', {'name': 'open'})<CR>"]])
          vim.keymap.set("n", "K", '<CMD>call ddu#ui#do_action("togglePreview")<CR>', opts)
        end,
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "ddu-ff",
        callback = function()
          common_keymaps()
          vim.keymap.set("n", "i", '<CMD>call ddu#ui#do_action("openFilterWindow")<CR>', opts)
          vim.keymap.set("n", "K", '<CMD>call ddu#ui#do_action("togglePreview")<CR>', opts)
          vim.keymap.set("n", "<C-q>", function()
            vim.fn["ddu#ui#ff#multi_actions"]({
              { "clearSelectAllItems" },
              { "toggleAllItems" },
              { "itemAction", { name = "quickfix" } },
            })
          end, opts)
        end,
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "ddu-ff-filter",
        callback = function()
          vim.keymap.set("n", "q", "<CMD>close<CR>", nowait)
          vim.keymap.set("n", "<ESC>", "<CMD>close<CR>", nowait)
          vim.keymap.set("i", "<CR>", "<CMD>close<CR><CMD>stopinsert<CR>", opts)
          vim.keymap.set("i", "<C-q>", function()
            vim.fn["ddu#ui#ff#multi_actions"]({
              { "clearSelectAllItems" },
              { "toggleAllItems" },
              { "itemAction", { name = "quickfix" } },
            })
          end, opts)
        end,
      })
    end,
  },
}
