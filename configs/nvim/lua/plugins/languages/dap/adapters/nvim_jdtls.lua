-- java lsp + debugger config
-- unlike other lsp servers, jdtls is not enabled via server_list.lua / vim.lsp.enable
-- (it needs a per-project workspace dir and debug/test bundles), so it is started
-- directly via nvim-jdtls on FileType java, following the plugin's own recommended setup
return {
	{
		"mfussenegger/nvim-jdtls",
		dependencies = { "mfussenegger/nvim-dap" },
		lazy = true,
		ft = { "java" },
		config = function()
			local uv = vim.uv or vim.loop
			local mason_share = vim.fn.stdpath("data") .. "/mason/share"
			local jdtls_share = mason_share .. "/jdtls"
			local launcher_jar = jdtls_share .. "/plugins/org.eclipse.equinox.launcher.jar"
			local lombok_jar = jdtls_share .. "/lombok.jar"
			local config_dir = jdtls_share .. "/config"
			local root_markers = {
				-- maven
				"pom.xml",
				"mvnw",
				-- gradle
				"build.gradle",
				"build.gradle.kts",
				"settings.gradle",
				"settings.gradle.kts",
				"gradlew",
				-- fallback
				".git",
			}
			-- collect java-debug / java-test bundles for nvim-dap integration
			local function collect_bundles()
				local bundles = {}
				local debug_jar = mason_share .. "/java-debug-adapter/com.microsoft.java.debug.plugin.jar"
				if uv.fs_stat(debug_jar) then
					table.insert(bundles, debug_jar)
				end
				local test_share = mason_share .. "/java-test"
				if uv.fs_stat(test_share) then
					local excluded = {
						"com.microsoft.java.test.runner-jar-with-dependencies.jar",
						"jacocoagent.jar",
					}
					for _, jar in ipairs(vim.fn.glob(test_share .. "/*.jar", true, true)) do
						if not vim.tbl_contains(excluded, vim.fn.fnamemodify(jar, ":t")) then
							table.insert(bundles, jar)
						end
					end
				end
				return bundles
			end
			-- attach jdtls (and nvim-dap) to the current java buffer
			local function attach_jdtls()
				local fname = vim.api.nvim_buf_get_name(0)
				local root_dir = vim.fs.root(fname, root_markers)
				if not root_dir then
					return
				end
				local project_name = vim.fs.basename(root_dir)
				local workspace_dir = vim.fn.stdpath("data") .. "/site/java-workspaces/" .. project_name
				local bundles = collect_bundles()
				require("jdtls").start_or_attach({
					name = "jdtls",
					cmd = {
						"java",
						"-Declipse.application=org.eclipse.jdt.ls.core.id1",
						"-Dosgi.bundles.defaultStartLevel=4",
						"-Declipse.product=org.eclipse.jdt.ls.core.product",
						"-Dlog.protocol=true",
						"-Dlog.level=ALL",
						"-Xmx2g",
						"--add-modules=ALL-SYSTEM",
						"--add-opens",
						"java.base/java.util=ALL-UNNAMED",
						"--add-opens",
						"java.base/java.lang=ALL-UNNAMED",
						"-javaagent:" .. lombok_jar,
						"-jar",
						launcher_jar,
						"-configuration",
						config_dir,
						"-data",
						workspace_dir,
					},
					root_dir = root_dir,
					settings = {
						java = {
							-- formatting is handled by google-java-format via efm (see servers/efm.lua)
							format = { enabled = false },
							eclipse = { downloadSources = true },
							maven = { downloadSources = true },
							implementationsCodeLens = { enabled = true },
							referencesCodeLens = { enabled = true },
							references = { includeDecompiledSources = true },
							inlayHints = {
								parameterNames = { enabled = "all" },
							},
						},
					},
					init_options = {
						bundles = bundles,
					},
					on_attach = function(_, bufnr)
						local jdtls = require("jdtls")
						-- register the java debug adapter with nvim-dap and enable main-class/test discovery
						if #bundles > 0 then
							jdtls.setup_dap({ hotcodereplace = "auto" })
							require("jdtls.dap").setup_dap_main_class_configs()
						end
						local opts = { buffer = bufnr, silent = true }
						vim.keymap.set(
							"n",
							"<LEADER>Jo",
							jdtls.organize_imports,
							vim.tbl_extend("force", opts, { desc = "java: organize imports" })
						)
						vim.keymap.set(
							"n",
							"<LEADER>Jv",
							jdtls.extract_variable,
							vim.tbl_extend("force", opts, { desc = "java: extract variable" })
						)
						vim.keymap.set("x", "<LEADER>Jv", function()
							jdtls.extract_variable(true)
						end, vim.tbl_extend("force", opts, { desc = "java: extract variable" }))
						vim.keymap.set(
							"n",
							"<LEADER>Jc",
							jdtls.extract_constant,
							vim.tbl_extend("force", opts, { desc = "java: extract constant" })
						)
						vim.keymap.set("x", "<LEADER>Jc", function()
							jdtls.extract_constant(true)
						end, vim.tbl_extend("force", opts, { desc = "java: extract constant" }))
						vim.keymap.set("x", "<LEADER>Jm", function()
							jdtls.extract_method(true)
						end, vim.tbl_extend("force", opts, { desc = "java: extract method" }))
						vim.keymap.set(
							"n",
							"<LEADER>Jt",
							jdtls.test_class,
							vim.tbl_extend("force", opts, { desc = "java: test class" })
						)
						vim.keymap.set(
							"n",
							"<LEADER>Jn",
							jdtls.test_nearest_method,
							vim.tbl_extend("force", opts, { desc = "java: test nearest method" })
						)
					end,
				})
			end
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "java",
				callback = attach_jdtls,
			})
			-- the autocmd above is registered after this plugin's own FileType event already
			-- fired (that's what triggered lazy-loading), so attach explicitly for that buffer
			attach_jdtls()
		end,
	},
}
