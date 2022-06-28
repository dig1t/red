local Players = game:GetService('Players')

local players = {}

local groupRankCache = {}

players.getGroupRank = function(player, groupId)
	local uniqueId = player.UserId .. groupId
	
	if not player or not groupId then
		return 0
	elseif not groupRankCache[uniqueId] then
		local success, res = pcall(function()
			return player:GetRankInGroup(groupId)
		end)
		
		groupRankCache[uniqueId] = res
		
		return success and res or 0
	else
		return groupRankCache[uniqueId]
	end
end

players.isCreator = function(player)
	return (
		game.CreatorType == Enum.CreatorType.Group and players.getGroupRank(player, game.CreatorId) >= 255
	) or (
		game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId
	)
end

local userLevel = {
	normal = 0;
	premium = 1;
	creator = 2;
}

players.userLevel = userLevel

players.getUserLevel = function(player)
	return (
		(players.isCreator(player) and userLevel.creator) or
		(player.MembershipType == Enum.MembershipType.Premium and userLevel.premium) or
		userLevel.normal
	)
end

players.getHumanoid = function(obj)
	return obj and typeof(obj) == 'Instance' and (
		(obj:IsA('Player') and obj.Character and obj.Character:FindFirstChild('Humanoid')) or
		(obj:IsA('Model') and obj:FindFirstChildOfClass('Humanoid')) or
		(obj:IsA('Humanoid') and obj) or
		nil -- Did not find a humanoid object
	)
end

players.isAlive = function(obj)
	local humanoid = players.getHumanoid(obj)
	
	return humanoid and humanoid.Health ~= 0
end

players.getPlayerFromPart = function(part)
	return (
		Players:GetPlayerFromCharacter(part and part.Parent)
	) or (
		-- Check if part is a wearable or tool
		Players:GetPlayerFromCharacter(part and part.Parent and part.Parent.Parent)
	)
end

return players