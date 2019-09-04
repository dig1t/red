-- src/ServerScriptStorage/red/Server.lua

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerScriptService = game:GetService('ServerScriptService')
local App = require(ReplicatedStorage.red.Root)
local _ = require(ReplicatedStorage.red.Util)
local cfg = require(ServerScriptService.red.ConfigSample)

local server = App.Server.new()
local store = App.Store.new()

--[[
	@desc teleports a player
	@param object player - player object
	@param object location - teleport point
]]--
server:bind('PLAYER_TELEPORT', function(player, location)
	if location and _.isAlive(player) then
		player.Character.Torso.CFrame = location.CFrame
	end
end)

game.Players.PlayerAdded:connect(function(player)
	player.Chatted:connect(function(message, recipient)
		if message == 'teleport' then
			server:localCall('PLAYER_TELEPORT', player, {
				player = player,
				location = Vector3.new(_.random(100, -100), 10, _.random(100, -100))
			})
		end
	end)
	
	player.CharacterAdded:connect(function(character)
		local humanoid = character:WaitForChild('Humanoid')
		
		if cfg.spawns then
			local spawn = _.randomObj(cfg.spawns)
			
			if spawn and character:FindFirstChild('Head') then
				local offset = spawn:FindFirstChild('Offset')
				
				if not offset then
					offset = { X = 8, Z = 8 }
				else
					offset = offset.Value
				end
				
				local X = _.random(offset.X, -offset.X)
				local Z = _.random(offset.Z, -offset.Z)
				
				wait()
				character.Head.CFrame = spawn.CFrame * CFrame.new(X, 8, Z)
			end
		end
	end)
	
	if cfg.events.entered then
		cfg.events.entered(player)
	end
end)

game.Players.PlayerRemoving:connect(function(player)
	if cfg.events.left then
		cfg.events.left(player)
	end
end)

-- Initiate the server

server:loadModules(script:GetChildren())

function App.error(err, userId)
	-- Override default error handler with a custom handler
	print(err)
	-- Handler examples: Post to external analytics site, show player the error, etc.
end

server:init()