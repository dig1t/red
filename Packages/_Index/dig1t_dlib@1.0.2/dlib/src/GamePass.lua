--[[
@name GamePass Checker
@author dig1t
@desc Game pass library that caches results and watches for pass purchases.
]]

local Marketplace = game:GetService('MarketplaceService')
local Players = game:GetService('Players')

local GamePass = {}

local connections = {}
local callbacks = {}
local purchases = {
	-- userId-passId = owned
}

function GamePass.has(userId, passId)
	assert(userId, 'GamePass.has - Missing user id')
	assert(passId, 'GamePass.has - Missing game pass id')
	
	local key = userId .. '-' .. passId
	
	if purchases[key] == nil then
		local success, res = pcall(function()
			return Marketplace:UserOwnsGamePassAsync(userId, passId)
		end)
		
		if success then
			purchases[key] = res
		else
			-- error(res)
			return false
		end
	end
	
	return purchases[key]
end

function GamePass.offer(player, passId)
	assert(passId, 'GamePass.offer - Missing game pass id')
	
	Marketplace:PromptGamePassPurchase(player, passId)
end

-- This function fixes the caching issue with UserOwnsGamePassAsync
-- by saving purchases made in the server. This allows the user to
-- continue playing without having to re-join.
function GamePass.watch()
	GamePass.unwatch() -- Prevent accidental multiple watchers
	
	connections[#connections + 1] = Marketplace.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if not purchased then
			return
		end
		
		purchases[player.UserId .. '-' .. passId] = true
		
		for _, callback in pairs(callbacks) do
			callback(player, passId)
		end
	end)
	
	connections[#connections + 1] = Players.PlayerRemoving:Connect(function(player)
		for id, own in pairs(purchases) do
			if string.sub(id, 1, #tostring(player.UserId) + 1) == player.UserId .. '-' then
				-- Remove cache record in case player purchased or deleted
				-- the game pass while they were not in the server
				purchases[id] = nil
			end
		end
	end)
end

-- Callbacks that are triggered when users purchase a game pass.
function GamePass.onPurchase(callback)
	callbacks[#callbacks + 1] = callback
end

function GamePass.unwatch()
	for i, connection in pairs(connections) do
		connection:Disconnect()
		connections[i] = nil
	end
end

return GamePass