local M = {}

-- open the app
M.OpenApp = function(appName)
	return function()
		hs.application.launchOrFocus(appName)
	end
end

-- disable keys
M.DisableAll = function(keySet)
	for _, v in pairs(keySet) do
		v:disable()
	end
end

-- enable keys
M.EnableAll = function(keySet)
	for _, v in pairs(keySet) do
		v:enable()
	end
end

return M
