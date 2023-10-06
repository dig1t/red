local ReplicatedStorage = game:GetService("ReplicatedStorage")

local red = require(ReplicatedStorage.red)
local dLib = require(ReplicatedStorage.red.dLib)
local Util = dLib.import("Util")

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
				location = CFrame.new(math.random(-100, 100), 10, math.random(-100, 100))
			}
		})
		
		task.wait(1)
		
		enabled = false 
	end
end)