-- src/ServerScriptStorage/red/Config.lua

local cfg = {}

cfg.build = '1.0.0'

cfg.spawns = game.Workspace.World.Spawns

cfg.events = {
	entered = function(player)
		print(player.Name, 'entered')
		wait()
		
		player.CameraMinZoomDistance = 5
		player.CameraMaxZoomDistance = 64
	end;
	
	entered = function(player)
		
	end;
	
	left = function(player)
		print(player.Name, 'left')
	end;
}

return cfg