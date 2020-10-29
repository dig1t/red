local players = {}

local groupRankCache = {}

players.getGroupRank = function(player, groupId)
	if not player or not groupId then
		return 0
	elseif not groupRankCache[player.UserId + groupId] then
		local success, res = pcall(function()
			return player:GetRankInGroup(groupId)
		end)
		
		groupRankCache[player.UserId + groupId] = res
		
		return success and res or 0
	else
		return groupRankCache[player.UserId + groupId]
	end
end

local firebit_id = 5113589
local creatorId = 31244132

players.isCreator = function(player) -- If game is owned by a group, add groupId arguments
	return (
		game.CreatorType == Enum.CreatorType.Group and players.getGroupRank(player, firebit_id) >= 255
	) or (
		game.CreatorType == Enum.CreatorType.User and player.UserId == creatorId
	)
end

local userLevel = {
	normal = 0;
	premium = 1;
	VIP = 2;
	moderator = 3;
	superuser = 4;
	creator = 5;
}

players.userLevel = userLevel

players.getUserLevel = function(player)
	return (
		(players.isCreator(player) and userLevel.creator) or
		(players.getGroupRank(player, firebit_id) >= 253 and userLevel.superuser) or
		(players.getGroupRank(player, firebit_id) >= 99 and userLevel.moderator) or
		(player.MembershipType == Enum.MembershipType.Premium and userLevel.premium) or
		userLevel.normal
	)
end

players.getHumanoid = function(obj)
	return obj and (
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
		game.Players:GetPlayerFromCharacter(part and part.Parent)
	) or (
		-- Check if part is a wearable or tool
		game.Players:GetPlayerFromCharacter(part and part.Parent and part.Parent.Parent)
	)
end

return players