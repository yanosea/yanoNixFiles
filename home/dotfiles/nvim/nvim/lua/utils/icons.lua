-- define icons
local M = {}
M.icons = {
	kind = {
		Array = "󰅪 ",
		Boolean = "◩ ",
		Class = "󰌗 ",
		Color = "",
		Constant = "󰏿 ",
		Constructor = " ",
		Enum = "󰕘",
		EnumMember = " ",
		Event = " ",
		Field = " ",
		File = "󰈙 ",
		Folder = "󰉋",
		Function = "󰊕 ",
		Interface = "󰕘",
		Key = "󰌋 ",
		Keyword = "",
		Method = "󰆧 ",
		Module = " ",
		Namespace = "󰌗 ",
		Null = "󰟢 ",
		Number = "󰎠 ",
		Object = "󰅩 ",
		Operator = "󰆕 ",
		Package = " ",
		Property = " ",
		Reference = "",
		Snippet = "",
		String = "󰀬 ",
		Struct = "󰌗 ",
		TypeParameter = "󰊄 ",
		Unit = "",
		Value = "",
		Variable = "󰆧 ",
	},
	git = {
		LineAdded = "",
		LineModified = "",
		LineRemoved = "",
		FileDeleted = "",
		FileIgnored = "◌",
		FileRenamed = "",
		FileStaged = "S",
		FileUnmerged = "",
		FileUnstaged = "",
		FileUntracked = "U",
		Diff = "",
		Repo = "",
		Octoface = "",
		Branch = "",
		Git = "",
	},
	ui = {
		ArrowCircleDown = "",
		ArrowCircleLeft = "",
		ArrowCircleRight = "",
		ArrowCircleUp = "",
		Blank = "․",
		BoldArrowDown = "",
		BoldArrowLeft = "",
		BoldArrowRight = "",
		BoldArrowUp = "",
		BoldClose = "",
		BoldDividerLeft = "",
		BoldDividerRight = "",
		BoldLineLeft = "▎",
		BookMark = "",
		BoxChecked = "",
		Bug = " ",
		BreakPoint = "",
		CommandLine = "",
		CommandLineInput = "󰥻",
		Stacks = "",
		Scopes = "",
		Watches = "󰂥",
		DebugConsole = "",
		Calendar = "",
		Check = "",
		ChevronRight = "",
		ChevronShortDown = "",
		ChevronShortLeft = "",
		ChevronShortRight = "",
		ChevronShortUp = "",
		Circle = " ",
		Circular = "",
		Clock = "",
		Close = "󰅖",
		CloudDownload = "",
		Code = "",
		Comment = "",
		Dashboard = "",
		DividerLeft = "",
		DividerRight = "",
		DoubleChevronRight = "»",
		Ellipsis = "",
		EmptyFolder = "",
		EmptyFolderOpen = "",
		File = "",
		FileSymlink = "",
		Files = "",
		Filter = "",
		FindFile = "󰈞",
		FindText = "󰊄",
		Fire = "",
		Folder = "󰉋",
		FolderOpen = "",
		FolderSymlink = "",
		Forward = "",
		Gear = "",
		History = "",
		Info = "󰋼",
		Lightbulb = "",
		LineLeft = "▏",
		LineMiddle = "│",
		LineHorizontal = "─",
		LineLeftTop = "┌",
		LineLeftBottom = "└",
		LineRightArrow = ">",
		List = "",
		Lock = "",
		NewFile = "",
		Note = "",
		Package = "",
		Pause = "",
		Pencil = "󰏫",
		Play = "",
		Plus = "",
		Project = "",
		Question = "",
		RunLast = "",
		Search = "",
		SearchBold = "",
		Separator = "󰄾",
		SignIn = "",
		SignOut = "",
		StepBack = "",
		StepInto = "",
		StepOver = "",
		StepOut = "",
		Stopwatch = "",
		Tab = "󰌒",
		Table = "",
		Target = "󰀘",
		Telescope = "",
		Terminate = "",
		Text = "",
		Tree = "󰔱",
		Triangle = "󰐊",
		TriangleShortArrowDown = "",
		TriangleShortArrowLeft = "",
		TriangleShortArrowRight = "",
		TriangleShortArrowUp = "",
		Warning = "",
	},
	scrollbars = {
		Min = "  ",
		Bar1 = "▁▁",
		Bar2 = "▂▂",
		Bar3 = "▃▃",
		Bar4 = "▄▄",
		Bar5 = "▅▅",
		Bar6 = "▆▆",
		Bar7 = "▇▇",
		Max = "██",
	},
	languages = {
		Lua = "",
	},
	diagnostics = {
		BoldError = "",
		Error = "",
		BoldWarning = "",
		Warning = "",
		BoldInformation = "",
		Information = "",
		BoldQuestion = "",
		Question = "",
		BoldHint = "",
		Hint = "󰌶",
		Debug = "",
		Trace = "✎",
	},
	misc = {
		CircuitBoard = "",
		Lazy = "󰒲",
		Mason = "󱌣",
		Package = "",
		Pin = "󰐃",
		Robot = "󰚩",
		Smiley = "",
		Squirrel = "",
		Tag = "",
		Watch = "",
	},
}
return M
