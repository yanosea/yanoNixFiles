return {
  {
    -- https://github.com/matsui54/denops-signature_help
    "matsui54/denops-signature_help",
    -- https://github.com/vim-denops/denops.vim
    dependencies = { "vim-denops/denops.vim" },
    config = function()
      vim.g.signature_help_config = {
        contentsStyle = "currentLabel",
        viewStyle = "virtual",
      }

      vim.fn["signature_help#enable"]()
    end,
  },
}
