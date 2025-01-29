local red = require(game.ReplicatedStorage.Packages.red)

return function(server: red.ServerType)
	server:bind("PING", function(player: Player)
		server:dispatch(player, { type = "PONG" })
	end)
end
