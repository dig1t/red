local cfg = {}

cfg.build = "1.0.0"

cfg.debug = true
cfg.dev = true

cfg.profileStoreName = "profiles_beta1.0"
cfg.saveProfiles = true

cfg.players = {
	trackTime = true -- track playtime
}

cfg.spawns = game.Workspace.World.Spawns

cfg.leaderboardStats = { "Money", "Level" }

cfg.defaultProfile = function(player)
	local profile = {}
	
	profile.uid = player.userId
	
	profile.statistics = {
		money = 25,
		total_time = 0,
		wood = 0
	}
	
	profile.market = {}
	
	-- Move to a separate data store
	profile.property_data = {
		[1] = {0, 0, 0};
		[2] = {8, 0, 0};
	}
	
	profile.playing = false
	profile.spectating = false
	
	return profile
end

cfg.events = {
	entered = function(player)
		task.wait()
		player.CameraMinZoomDistance = 5
		player.CameraMaxZoomDistance = 64
	end;
}

-- set to true if using a  custom analytics service (e.g. Google Analytics)
cfg.useAnalytics = false

return cfg