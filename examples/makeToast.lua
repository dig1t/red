local ReplicatedStorage = game:GetService('ReplicatedStorage')

local red = require(ReplicatedStorage.red)
local dLib = require(ReplicatedStorage.red.Packages.dLib)
local Util = dLib.import('Util')

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
		
		Util.yield(1)
		
		enabled = false 
	end
end)
