local red = require(game.ReplicatedStorage.Packages.red)

return function(server: red.ServerType)
	server:bind("GET_DATA", function(_player: Player)
		print("Getting data...")
		task.wait(1)

		return {
			type = "DATA",
			payload = { data = "Hello, world!" },
		}
	end)
end
