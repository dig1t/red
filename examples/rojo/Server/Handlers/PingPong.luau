local red = require(game.ReplicatedStorage.Packages.red)

return function(bind: red.Bind)
	bind("PING", function(player: Player)
		red.dispatch(player, { type = "PONG" })
	end)
end
