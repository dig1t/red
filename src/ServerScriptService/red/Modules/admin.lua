-- src/ServerScriptStorage/red/Modules/admin.lua

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerScriptService = game:GetService('ServerScriptService')
local DataStore = game:GetService('DataStoreService')
local App = require(ReplicatedStorage.red.Root)
local _ = require(ReplicatedStorage.red.Util)
local cfg = require(ServerScriptService.red.Config)

local store = App.Store.new()
local blacklist

if not cfg.dev then
	blacklist = DataStore:GetDataStore('UserBlacklist')
end

local admin = {}

admin.name = 'admin'
admin.version = '1.0.0'

function getPlayer(player, text, ignoreAdmins, checkForCharacter)
	local targets = {}
	
	if text == 'me' or not text then
		targets = { player }
	elseif text == 'all' then
		targets = game.Players:GetPlayers()
	elseif text == 'others' then
		targets = game.Players:GetPlayers()
		
		for i, v in pairs(targets) do
			if v == player then
				table.remove(targets, i)
			end
		end
	else
		for k, player in pairs(game.Players:GetPlayers()) do
			if string.lower(player.Name):match(string.lower(text)) and (ignoreAdmins and not admin.check(player) or true) then
				targets = { player }
				break
			end
		end
	end
	
	if checkForCharacter then
		for i, player in pairs(targets) do
			if not player.Character or not player.Character.PrimaryPart then
				table.remove(targets, i)
			end
		end
	end
	
	return targets
end

admin.commands = {
	kill = function(player, targets)
		for k, target in pairs(getPlayer(player, targets)) do
			target.Character:BreakJoints()
		end
	end;
	
	ff = function(player, targets)
		for k, target in pairs(getPlayer(player, targets)) do
			Instance.new('ForceField', target.Character)
		end
	end;
	
	-- if no destination then tp to first target in list
	tp = function(player, targets, destination)
		local targets = getPlayer(player, targets, false, true)
		
		if #targets == 0 then return end
		
		local destination
		
		if not destination then
			destination = targets
			targets = { player }
		else
			destination = getPlayer(player, destination, false, true)
		end
		
		if #destination > 1 then -- only one destination target
			destination = destination[1]
		else
			return
		end
		
		for k, target in pairs(targets) do
			if target.Character.PrimaryPart then
				target.Character.PrimaryPart.CFrame = destination.Character.PrimaryPart.CFrame
			end
		end
	end;
	
	unjail = function(player, targets)
		local targets = getPlayer(player, targets, false, true)
		
		for k, target in pairs(targets) do
			local jailName = 'Jail'..target.Name
			
			if game.Workspace:FindFirstChild(jailName) then
				game.Workspace[jailName]:Destroy()
			end
		end
	end;
	
	jail = function(player, targets)
		local targets = getPlayer(player, targets, false, true)
		
		if #targets == 0 then return end
		
		local radius = 5
		local bars = 16
		local height = 10
		local thickness = .5
		
		local partConfig = { BrickColor = BrickColor.Black(), Transparency = _.minTransparencySeeThru, surface = Enum.SurfaceType.Smooth, Anchored = true }
		local bar = _(_.extend({ Size = Vector3.new(2.5, height, thickness) }, partConfig))
		local cap = _(_.extend({
			Size = Vector3.new(thickness, radius * 2 + thickness, radius * 2 + thickness),
			mesh = true, meshType = 'SpecialMesh', meshSpecialType = Enum.MeshType.Cylinder
		}, partConfig))
		
		for k, target in pairs(targets) do
			local jailName = 'Jail'..target.Name
			
			if game.Workspace:FindFirstChild(jailName) then
				game.Workspace[jailName]:Destroy()
			end
			
			local jail = _({ class = 'Model', name = jailName, parent = game.Workspace })
			local top, bottom = cap:Clone(), cap:Clone()
			local center = target.Character.PrimaryPart
			
			center.Anchored = true
			
			for i = 1, bars do
				local sine = math.sin((360 / bars + 360 / bars * i) / (180 / math.pi))
				local cosine = math.cos((360 / bars + 360 / bars * i) / (180 / math.pi))
				local newBar = bar:Clone()
				
				newBar.Parent = jail
				newBar.CFrame = center.CFrame
					* CFrame.new(radius * sine, 0, radius * cosine)
					* CFrame.fromEulerAnglesXYZ(0, (360 / bars + 360 / bars * i) / (180 / math.pi), 0)
				
				wait()
			end
			
			top.CFrame = center.CFrame * CFrame.new(0, (height / 2) + (thickness / 2), 0) * CFrame.fromEulerAnglesXYZ(0, 0, math.rad(90))
			bottom.CFrame = center.CFrame * CFrame.new(0, (height / -2) + (thickness / 2), 0) * CFrame.fromEulerAnglesXYZ(0, 0, math.rad(90))
			
			top.Parent = jail
			wait()
			bottom.Parent = jail
			center.Anchored = false
		end
	end;
	
	moon = function(player, targets)
		local targets = getPlayer(player, targets, false, true)
		
		for k, target in pairs(targets) do
			_({
				class = 'BodyForce',
				name = 'LowGrav',
				force = Vector3.new(0, 1800, 0),
				parent = target.Character.PrimaryPart
			})
		end
	end;
	
	freeze = function(player, targets)
		local targets = getPlayer(player, targets, false, true)
		
		for k, target in pairs(targets) do
			target.Character.PrimaryPart.Anchored = true
		end
	end;
	
	thaw = function(player, targets)
		local targets = getPlayer(player, targets, false, true)
		
		for k, target in pairs(targets) do
			target.Character.PrimaryPart.Anchored = false
		end
	end;
	
	unban = function(player, userId)
		local userId = tonumber(userId)
		
		if userId then
			admin.unban(userId)
		end
	end;
}

admin.check = function(player)
	return {
		type = 'ADMIN_CHECK',
		payload = player.userId == 31244132 or player:IsFriendsWith(31244132) or script.Parent.Parent.Admin:FindFirstChild(string.lower(player.Name))
	}
end

local prefix = '/'

admin.spoke = function(player, payload)
	local msgTest = string.lower(payload.message)
	
	if msgTest:match('kick') and #msgTest > 7 then
		local target = getPlayer(player, msgTest:sub(6))
		
		if target then
			admin.kick(target)
		end
	end
	
	if msgTest:match('ban') and #msgTest > 8 then
		local target = getPlayer(player, msgTest:sub(5), true)
		
		if target then
			admin.ban(target)
		end
	end
	
	if not msgTest:sub(0, prefix:len()) == prefix then return end
	
	local sections = payload.message:sub(prefix:len() + 1):split(' ')
	
	if #sections == 0 then return end
	
	local command = sections[1]
	
	table.remove(sections, 1)
	
	if admin.commands[command] then
		admin.commands[command](player, unpack(sections))
	end
end

admin.kick = function(player, payload)
	player:Kick(payload or 'Kicked by an admin')
end

admin.ban = function(player)
	if player and player:IsA('Player') and player.userId > 0 then
		local success, err = pcall(function() -- REPLACE WITH _.ATTEMPT()
			if not cfg.dev then blacklist:SetAsync(player.userId, true) end
		end)
		
		if not err then
			-- log error
		end
		
		admin.kick(player, 'Banned by an admin')
	end
end

admin.unban = function(userId)
	if tonumber(userId) > 0 then
		local success, value = pcall(function() -- REPLACE WITH _.ATTEMPT()
			return not cfg.dev and blacklist:RemoveAsync(userId) or nil
		end)
		
		if not success then
			-- log error
		end
	end
end

admin.check_if_banned = function(userId)
	local success, flag = pcall(function() -- REPLACE WITH _.ATTEMPT()
		return not cfg.dev and blacklist:GetAsync(userId) or nil
	end)
	
	if not success then
		-- log error
	end
	
	return {
		type = 'CHECK_IF_BANNED',
		payload = flag
	}
end

return admin