-- lunarvim config entry point
-- common config
require("helper.loader").load_lua_files(vim.fn.stdpath("config") .. "/lua/config")
-- core plugins
require("helper.loader").load_lua_files(vim.fn.stdpath("config") .. "/lua/core")
-- user plugins
require("helper.loader").load_lua_files(vim.fn.stdpath("config") .. "/lua/user")
-- language plugins
require("helper.loader").load_lua_files(vim.fn.stdpath("config") .. "/lua/language")
