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
			type = 'UI_TOAST',
			player = player,
			payload = {
				message = 'Touched red part '.._.unix()
			}
		})
		wait(1)
		enabled = false 
	end
end)