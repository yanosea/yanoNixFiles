-- prompts module
local M = {}
 -- load all prompt modules
M.system_prompt = require("plugins.tools.external.ai.prompts.system_prompt").system_prompt
M.user_prompts = require("plugins.tools.external.ai.prompts.user_prompts").user_prompts
return M
