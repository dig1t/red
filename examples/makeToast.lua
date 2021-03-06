local ReplicatedStorage = game:GetService('ReplicatedStorage')

local red = require(ReplicatedStorage.Lib.red.Root)
local Util = require(ReplicatedStorage.Lib.red.Util)

local store = red.Store.new()

local enabled = false

script.Parent.Touched:Connect(function(part)
	if enabled then
		return
	end
	
	local player = Util.getPlayerFromPart(part)
	
	if player then
		enabled = true
		
		store:dispatch({
			type = 'UI_TOAST',
			player = player,
			payload = {
				message = 'Touched red part ' .. os.clock()
			}
		})
		
		wait(1)
		
		enabled = false 
	end
end)
