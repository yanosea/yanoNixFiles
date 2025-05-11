return {
  {
    "mfussenegger/nvim-dap",
    lazy = true,
    event = "VeryLazy",
    config = function()
      local icons = require("utils.icons").icons
      local dap = require("dap")
      vim.fn.sign_define("DapBreakpoint", {
        text = icons.ui.Bug,
        texthl = "DiagnosticSignError",
        linehl = "",
        numhl = "",
      })
      vim.fn.sign_define("DapBreakpointRejected", {
        text = icons.ui.Bug,
        texthl = "DiagnosticSignError",
        linehl = "",
        numhl = "",
      })
      vim.fn.sign_define("DapStopped", {
        text = icons.ui.BoldArrowRight,
        texthl = "DiagnosticSignWarn",
        linehl = "Visual",
        numhl = "DiagnosticSignWarn",
      })
      dap.set_log_level("info")
    end
  },
}
