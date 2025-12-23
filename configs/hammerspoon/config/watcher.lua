-- watcher
---- restart SwipeAeroSpace on wake/unlock events
hs.caffeinate.watcher
	.new(function(event)
		local wakeEvents = {
			[hs.caffeinate.watcher.systemDidWake] = true,
			[hs.caffeinate.watcher.screensDidWake] = true,
			[hs.caffeinate.watcher.screensaverDidStop] = true,
			[hs.caffeinate.watcher.screensaverWillStop] = true,
			[hs.caffeinate.watcher.sessionDidBecomeActive] = true,
		}
		if wakeEvents[event] then
			hs.execute("/usr/bin/killall -9 SwipeAeroSpace 2>/dev/null", true)
			hs.execute("/usr/bin/open -a SwipeAeroSpace", true)
		end
	end)
	:start()
