local ReplicatedStorage = game:GetService('ReplicatedStorage')
local Players = game:GetService('Players')

local red = require(ReplicatedStorage.Lib.red)
local Util = require(ReplicatedStorage.Lib.Util)

local server = red.Server.new()

do -- Initialize
	--server:loadModules(script:GetChildren())
	server:init()
	
	function server.error(err, userId) -- Override default error handler
		--server:localCall('ANALYTICS_ERROR', err, userId)
		error(err, 2)
	end
end

--[[
	@desc teleports a player
	@param object player - player object
	@param object location - teleport point
]]--
server:bind('PLAYER_TELEPORT', function(player, payload)
	if Util.isAlive(player) then
		Util.yield()
		
		player.Character.PrimaryPart.CFrame = payload.location
	end
end)

local function playerAdded(player)
	player.CharacterAdded:Connect(function(character)
		if not character.Parent then
			character.AncestryChanged:Wait()
			
			if not character.Parent then
				return
			end
		end
		
		character:WaitForChild('Humanoid')
		
		server:call({
			type = 'PLAYER_TELEPORT',
			player = player,
			payload = {
				location = CFrame.new(math.random(-100, 100), 40, math.random(-100, 100))
			}
		})
	end)
end

-- Add players that joined before the connection was created
for _, player in pairs(Players:GetPlayers()) do
	playerAdded(player)
end

Players.PlayerAdded:Connect(playerAdded)