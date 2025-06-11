-- setup lsp servers
local M = {}
function M.setup(servers)
	local servers_config_path = "plugins.languages.lsp.servers"
	for _, server in ipairs(servers) do
		local ok, server_config = pcall(require, servers_config_path .. "." .. server:gsub("-", "_"))
		if ok then
			-- if server has a config file, load it
			server_config.setup()
		else
			-- if server doesn't have a config file, use default config
			vim.lsp.config(server, {})
		end
		-- enable the server
		vim.lsp.enable(server)
	end
end
return M
