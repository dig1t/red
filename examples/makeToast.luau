--!nocheck

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Util = require(ReplicatedStorage.Packages.Util)
local red = require(ReplicatedStorage.Packages.red)

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
			type = "UI_TOAST",
			player = player,
			payload = {
				message = "Touched red part " .. os.clock(),
			},
		})

		task.wait(1)

		enabled = false
	end
end)
