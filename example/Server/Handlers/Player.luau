local red = require(game.ReplicatedStorage.Packages.red)

local PlayerController = require(script.Parent.Parent.Controllers.PlayerController)

return function(server: red.ServerType)
	server:bind("PLAYER_KILL", function(player: Player)
		local success = PlayerController.kill(player)

		if success then
			server:dispatch(true, { type = "PLAYER_KILLED", payload = player.Name })
		end
	end)

	server:bind(
		"PLAYER_DAMAGE",
		function(player: Player, payload: red.ActionPayload<{ amount: number }>)
			PlayerController.damage(player, payload.amount)
		end
	)
end
