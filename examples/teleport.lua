local ReplicatedStorage = game:GetService('ReplicatedStorage')

local App = require(ReplicatedStorage.red.Root)
local _ = require(ReplicatedStorage.red.Util)

local store = App.Store.new()

local enabled = false

script.Parent.Touched:connect(function(part)
	if enabled then
		return
	end
	
	local player = _.getPlayerFromPart(part)
	
	if player then
		enabled = true
		store:dispatch({
			type = 'PLAYER_TELEPORT',
			player = player,
			payload = {
				location = CFrame.new(math.random(-100, 100), 10, math.random(-100, 100))
			}
		})
		wait(1)
		enabled = false 
	end
end)