local colors = require("colors")
local settings = require("settings")

local menu_watcher = Sbar.add("item", {
	drawing = false,
	updates = false,
})
local space_menu_swap = Sbar.add("item", {
	drawing = false,
	updates = true,
})
Sbar.add("event", "swap_menus_and_spaces")

local max_items = 15
local menu_items = {}
for i = 1, max_items, 1 do
	local menu = Sbar.add("item", "menu." .. i, {
		padding_left = settings.paddings,
		padding_right = settings.paddings,
		drawing = false,
		icon = { drawing = false },
		label = {
			font = {
				style = settings.font.style_map[i == 1 and "Heavy" or "Semibold"],
			},
			padding_left = 6,
			padding_right = 6,
		},
		click_script = "$CONFIG_DIR/helpers/menus/bin/menus -s " .. i,
	})

	menu_items[i] = menu
end

Sbar.add("bracket", { "/menu\\..*/" }, {
	background = { color = colors.bg1 },
})

local menu_padding = Sbar.add("item", "menu.padding", {
	drawing = false,
	width = 5,
})

local function update_menus(_)
	Sbar.exec("$CONFIG_DIR/helpers/menus/bin/menus -l", function(menus)
		Sbar.set("/menu\\..*/", { drawing = false })
		menu_padding:set({ drawing = true })
		Id = 1
		for menu in string.gmatch(menus, "[^\r\n]+") do
			if Id < max_items then
				menu_items[Id]:set({ label = menu, drawing = true })
			else
				break
			end
			Id = Id + 1
		end
	end)
end

menu_watcher:subscribe("front_app_switched", update_menus)

space_menu_swap:subscribe("swap_menus_and_spaces", function(_)
	local drawing = menu_items[1]:query().geometry.drawing == "on"
	if drawing then
		menu_watcher:set({ updates = false })
		Sbar.set("/menu\\..*/", { drawing = false })
		Sbar.set("/space\\..*/", { drawing = true })
		Sbar.set("front_app", { drawing = true })
	else
		menu_watcher:set({ updates = true })
		Sbar.set("/space\\..*/", { drawing = false })
		Sbar.set("front_app", { drawing = false })
		update_menus()
	end
end)

return menu_watcher
