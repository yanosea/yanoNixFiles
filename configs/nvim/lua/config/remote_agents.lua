-- Happier terminal integration.
local remote_agent = require("utils.remote_agent")

local M = {}

M.happier = remote_agent.new({
	command = "happier",
	label = "HAPPIER",
})

if M.happier then
	vim.api.nvim_create_user_command("Happier", M.happier.toggle, {
		desc = "Toggle Happier terminal and prompt layout",
	})
end

return M
