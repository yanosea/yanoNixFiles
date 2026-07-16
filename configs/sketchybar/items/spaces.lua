local colors = require("colors")
local icons = require("icons")
local settings = require("settings")
local app_icons = require("helpers.app_icons")

local spaces = {}
local space_brackets = {}
local space_paddings = {}

-- aerospace has no native sketchybar integration like yabai does, so
-- visibility/highlighting/icons are driven manually via aerospace.toml's
-- exec-on-workspace-change hook plus periodic polling (space_observer below)
local function set_space_label(i, apps)
	local seen = {}
	local icon_line = ""
	local no_app = true
	for _, app in ipairs(apps) do
		if not seen[app] then
			seen[app] = true
			no_app = false
			local lookup = app_icons[app]
			local icon = ((lookup == nil) and app_icons["default"] or lookup)
			icon_line = icon_line .. " " .. icon
		end
	end
	if no_app then
		icon_line = " —"
	end
	Sbar.animate("tanh", 10, function()
		spaces[i]:set({ label = icon_line })
	end)
end

local function highlight_space(i, focused_workspace)
	local selected = tostring(i) == focused_workspace
	spaces[i]:set({
		icon = { highlight = selected },
		label = { highlight = selected },
		background = { border_color = selected and colors.black or colors.bg2 },
	})
	space_brackets[i]:set({
		background = { border_color = selected and colors.grey or colors.bg2 },
	})
end

local function refresh_spaces()
	Sbar.exec("aerospace list-workspaces --focused", function(focused_result)
		local focused_workspace = focused_result:gsub("%s+$", "")

		Sbar.exec("aerospace list-windows --monitor all --format '%{workspace}|%{app-name}'", function(windows_result)
			local apps_by_space = {}
			for i = 1, 10 do
				apps_by_space[i] = {}
			end
			for line in windows_result:gmatch("[^\r\n]+") do
				local ws, app = line:match("^(%d+)|(.*)$")
				ws = tonumber(ws)
				if ws and apps_by_space[ws] and app ~= "" then
					table.insert(apps_by_space[ws], app)
				end
			end

			for i = 1, 10 do
				local visible = (tostring(i) == focused_workspace) or (#apps_by_space[i] > 0)
				spaces[i]:set({ drawing = visible })
				space_brackets[i]:set({ drawing = visible })
				space_paddings[i]:set({ drawing = visible })

				if visible then
					highlight_space(i, focused_workspace)
					set_space_label(i, apps_by_space[i])
				end
			end
		end)
	end)
end

for i = 1, 10, 1 do
	local space = Sbar.add("item", "space." .. i, {
		icon = {
			font = { family = settings.font.numbers },
			string = i,
			padding_left = 15,
			padding_right = 8,
			color = colors.white,
			highlight_color = colors.blue,
		},
		label = {
			padding_right = 20,
			color = colors.grey,
			highlight_color = colors.white,
			font = "sketchybar-app-font:Regular:16.0",
			y_offset = -1,
		},
		padding_right = 1,
		padding_left = 1,
		background = {
			color = colors.bg1,
			border_width = 1,
			height = 26,
			border_color = colors.black,
		},
		popup = { background = { border_width = 5, border_color = colors.black } },
	})

	spaces[i] = space

	-- Single item bracket for space items to achieve double border on highlight
	local space_bracket = Sbar.add("bracket", { space.name }, {
		background = {
			color = colors.transparent,
			border_color = colors.bg2,
			height = 28,
			border_width = 2,
		},
	})
	space_brackets[i] = space_bracket

	-- Padding space
	local space_padding = Sbar.add("item", "space.padding." .. i, {
		script = "",
		width = settings.group_paddings,
	})
	space_paddings[i] = space_padding

	local space_popup = Sbar.add("item", {
		position = "popup." .. space.name,
		padding_left = 5,
		padding_right = 0,
		background = {
			drawing = true,
			image = {
				corner_radius = 9,
				scale = 0.2,
			},
		},
	})

	space:subscribe("mouse.clicked", function(env)
		if env.BUTTON == "other" then
			space_popup:set({ background = { image = "space." .. i } })
			space:set({ popup = { drawing = "toggle" } })
		else
			Sbar.exec("aerospace workspace " .. i)
		end
	end)

	space:subscribe("mouse.exited", function(_)
		space:set({ popup = { drawing = false } })
	end)
end

-- single observer drives refreshes, avoiding 10x redundant aerospace calls per event
local space_observer = Sbar.add("item", {
	drawing = false,
	updates = true,
	update_freq = 2,
})
space_observer:subscribe({ "aerospace_workspace_change", "routine", "system_woke" }, refresh_spaces)

refresh_spaces()

local spaces_indicator = Sbar.add("item", {
	padding_left = -3,
	padding_right = 0,
	icon = {
		padding_left = 8,
		padding_right = 9,
		color = colors.grey,
		string = icons.switch.on,
	},
	label = {
		width = 0,
		padding_left = 0,
		padding_right = 8,
		string = "Spaces",
		color = colors.bg1,
	},
	background = {
		color = colors.with_alpha(colors.grey, 0.0),
		border_color = colors.with_alpha(colors.bg1, 0.0),
	},
})

spaces_indicator:subscribe("swap_menus_and_spaces", function(_)
	local currently_on = spaces_indicator:query().icon.value == icons.switch.on
	spaces_indicator:set({
		icon = currently_on and icons.switch.off or icons.switch.on,
	})
end)

spaces_indicator:subscribe("mouse.entered", function(_)
	Sbar.animate("tanh", 30, function()
		spaces_indicator:set({
			background = {
				color = { alpha = 1.0 },
				border_color = { alpha = 1.0 },
			},
			icon = { color = colors.bg1 },
			label = { width = "dynamic" },
		})
	end)
end)

spaces_indicator:subscribe("mouse.exited", function(_)
	Sbar.animate("tanh", 30, function()
		spaces_indicator:set({
			background = {
				color = { alpha = 0.0 },
				border_color = { alpha = 0.0 },
			},
			icon = { color = colors.grey },
			label = { width = 0 },
		})
	end)
end)

spaces_indicator:subscribe("mouse.clicked", function(_)
	Sbar.trigger("swap_menus_and_spaces")
end)
