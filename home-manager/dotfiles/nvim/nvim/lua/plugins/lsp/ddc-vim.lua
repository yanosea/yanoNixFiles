return {
  {
    -- https://github.com/Shougo/ddc.vim
    "Shougo/ddc.vim",
    lazy = false,
    dependencies = {
      -- https://github.com/vim-denops/denops.vim
      "vim-denops/denops.vim",
      -- ui
      -- https://github.com/Shougo/pum.vim
      "Shougo/pum.vim",
      -- https://github.com/Shougo/ddc-ui-pum
      "Shougo/ddc-ui-pum",
      -- source
      -- https://github.com/Shougo/ddc-source-around
      "Shougo/ddc-source-around",
      -- https://github.com/Shougo/ddc-source-lsp
      "Shougo/ddc-source-lsp",
      -- https://github.com/LumaKernel/ddc-source-file
      "LumaKernel/ddc-source-file",
      -- firter
      -- https://github.com/Shougo/ddc-filter-matcher_head
      "Shougo/ddc-matcher_head",
      -- https://github.com/Shougo/ddc-filter-sorter_rank
      "Shougo/ddc-sorter_rank",
      -- https://github.com/Shougo/Shougo/ddc-filter-converter_truncate_abbr
      "Shougo/ddc-filter-converter_truncate_abbr",
      -- https://github.com/Shougo/ddc-filter-converter_remove_overlap
      "Shougo/ddc-converter_remove_overlap",
      -- preview
      -- https://github.com/uga-rosa/ddc-previewer-floating
      "uga-rosa/ddc-previewer-floating",
      -- https://github.com/matsui54/denops-signature_help
      "matsui54/denops-signature_help",
    },
    config = function()
      local patch_global = vim.fn["ddc#custom#patch_global"]

      patch_global("ui", "pum")

      patch_global("sources", {
        "skkeleton",
        "lsp",
        "file",
        "around",
      })

      patch_global("sourceOptions", {
        _ = {
          matchers = { "matcher_head" },
          sorters = { "sorter_rank" },
          converters = { "converter_truncate_abbr", "converter_remove_overlap" },
          ignoreCase = true,
        },
        around = {
          mark = "[A]",
        },
        lsp = {
          mark = "[LS]",
          dup = "keep",
          keywordPattern = "[a-zA-Z0-9_À-ÿ$#\\-*]*",
          forceCompletionPattern = [[\.\w*|:\w*|->\w*]],
          sorters = { "sorter_lsp-kind", "sorter_rank" },
        },
        file = {
          mark = "[F]",
          isVolatile = true,
          forceCompletionPattern = [[\S/\S*]],
        },
        skkeleton = {
          mark = "[SKK]",
          matchers = { "skkeleton" },
          sorters = {},
          isVolatile = true,
          minAutoCompleteLength = 2,
        },
      })

      patch_global("sourceParams", {
        lsp = {
          enableResolveItem = true,
          enableAdditionalTextEdit = true,
          confirmBehavior = "replace",
        },
      })

      vim.fn["ddc#enable"]()
      require("ddc_previewer_floating").enable()
    end,
  },
}
