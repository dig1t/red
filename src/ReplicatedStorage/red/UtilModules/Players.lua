-- src/ReplicatedStorage/red/UtilModules/Players.lua

local players = {}

players.getHumanoid = function(obj)
	if not obj then return end
	
	local res
	
	if obj:IsA('Player') and obj.Character and obj.Character:FindFirstChild('Humanoid') then
		res = obj.Character.Humanoid
	elseif obj:IsA('Model') then
		for k, v in pairs(obj:GetChildren()) do
			if v:IsA('Humanoid') then
				res = v
				break
			end
		end
	elseif obj:IsA('Humanoid') then
		res = obj
	end
	
	return res
end

players.isAlive = function(obj)
	local humanoid = players.getHumanoid(obj)
	
	if humanoid then
		return humanoid.Health ~= 0
	end
end

players.getTeam = function(player)
	if not player:IsA('Player') then return end
	
	local team
	
	if game:FindFirstChild('Teams') then
		for k, v in pairs(game.Teams:GetChildren()) do
			if v.TeamColor == player.TeamColor then
				team = v.Name
			end
		end
	end
	
	return player.TeamColor, team
end

players.getPlayerFromPart = function(part)
	return (
		part and part.Parent and game.Players:GetPlayerFromCharacter(part.Parent)
	) or (
		-- Check if part is a hat or tool that is on a character
		part.Parent.Parent and game.Players:GetPlayerFromCharacter(part.Parent.Parent)
	)
end

return players