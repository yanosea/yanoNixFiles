-- user prompts module
local M = {}
-- load all prompt modules
M.user_prompts = {
  Explain = require("plugins.tools.external.ai.prompts.user_prompts.explain"),
  Review = require("plugins.tools.external.ai.prompts.user_prompts.review"),
  Fix = require("plugins.tools.external.ai.prompts.user_prompts.fix"),
  Optimize = require("plugins.tools.external.ai.prompts.user_prompts.optimize"),
  Docs = require("plugins.tools.external.ai.prompts.user_prompts.docs"),
  Tests = require("plugins.tools.external.ai.prompts.user_prompts.tests"),
  FixDiagnostic = require("plugins.tools.external.ai.prompts.user_prompts.fix_diagnostic"),
  Commit = require("plugins.tools.external.ai.prompts.user_prompts.commit"),
}
return M
