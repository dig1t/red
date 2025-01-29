local ReplicatedStorage = game:GetService("ReplicatedStorage")

local red = require(ReplicatedStorage.Packages.red)

red.subscribe(function(action: red.Action<any>)
	if action.type == "PLAYER_KILL" then
		print(`{action.payload} was killed!`)
	end
end)

-- "get" will wait for a result
local data = red.get({ type = "GET_DATA" })

if data.success then
	print(data.payload.data) -- Hello, world!
end
