local BadgeService = game:GetService('BadgeService')

local badges = {}

local Badge = {}
local cache = {}

function Badge.add(name, badgeId)
	badges[name] = badgeId
end

function Badge.has(userId, badgeName)
	assert(userId, 'Badge.award - Missing user id')
	assert(badgeName, 'Badge.award - Missing badge name')
	
	if not badges[badgeName] then
		warn('"' .. badgeName .. '" badge does not exist')
		return
	end
	
	local cached = cache[userId .. '-' .. badgeName]
	
	if cached == nil then
		cached = BadgeService:UserHasBadgeAsync(userId, badges[badgeName])
		cache[userId .. '-' .. badgeName] = cached
		
		return cached
	end
end

function Badge.award(userId, badgeName)
	assert(userId, 'Badge.award - Missing user id')
	assert(badgeName, 'Badge.award - Missing badge name')
	
	coroutine.wrap(function()
		if not Badge.has(userId, badgeName) then
			BadgeService:AwardBadge(userId, badges[badgeName])
		end
	end)()
end

return Badge