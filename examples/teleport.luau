--!nocheck

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Util = require(ReplicatedStorage.Packages.Util)
local red = require(ReplicatedStorage.Packages.red)

local store = red.Store.new()

local enabled = false

script.Parent.Touched:connect(function(part)
	if enabled then
		return
	end

	local player = Util.getPlayerFromPart(part)

	if player then
		enabled = true

		store:dispatch({
			type = "PLAYER_TELEPORT",
			player = player,
			payload = {
				location = CFrame.new(Util.random(-100, 100), 10, Util.random(-100, 100)),
			},
		})

		task.wait(1)

		enabled = false
	end
end)
