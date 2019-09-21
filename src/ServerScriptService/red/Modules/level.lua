-- src/ServerScriptStorage/red/Modules/level.lua

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local App = require(ReplicatedStorage.red.Root)
local _ = require(ReplicatedStorage.red.Util)

local store = App.Store.new()

local levelSys = {}

levelSys.name = 'level'
levelSys.version = '1.0.0'

function calculate(xp)
	return math.floor((32 + math.sqrt(32 * 32 - 4 * 32 * (-xp))) / (2 * 32))
end

--[[
	- @desc returns xp required to reach level
	- @param int level - current level
]]--
function xpRequired(level)
	return 32 * level * level - 32 * level
end

-- calculates the gap between the users current level and the next level
function xpGap(xp)
	return xpRequired(calculate(xp) + 1) - xp
end

function progressPercentage(xp)
	local level = calculate(xp)
	local currentLevelXP = xpRequired(level)
	
	return (xp - currentLevelXP) / (xpRequired(level + 1) - currentLevelXP)
end

------------------------------
-- xp/level system

--[[
	- @desc returns a user's xp
	- @param object player - player
]]--
levelSys.xp = function(player)
	return store:get({
		type = 'PROFILE_GET',
		player = player,
		payload = {
			tbl = 'statistics',
			key = 'xp'
		}
	}).payload
end

--[[
	- @desc returns a user's level using the user's current xp
	- @param object player - player
]]--
levelSys.get = function(player)
	return {
		type = 'LEVEL_GET',
		payload = calculate(levelSys.xp(player))
	}
end

--[[
	- @desc returns xp needed to level up for a user
	- @param object player - player
]]--
levelSys.xp_needed = function(player)
	return {
		type = 'LEVEL_XP_NEEDED',
		payload = xpGap(levelSys.xp(player))
	}
end

--[[
	- @desc returns a user's level progress percentage
	- @param object player - player
]]--
levelSys.progress = function(player)
	return {
		type = 'LEVEL_PROGRESS',
		payload = progressPercentage(levelSys.xp(player))
	}
end

--[[
	- @desc returns level overview in an event
	- @param object player - player
	- @param object target - user to get statistics from (optional)
	- @param boolean dispatch - dispatch to user
]]--
levelSys.overview = function(player, payload)
	local xp = levelSys.xp(payload and payload.target or player)
	local stats = {}
	
	if xp then
		stats.xp = xp
		stats.level = calculate(xp)
		stats.xpRequired = xpRequired(stats.level + 1)
		stats.levelProgress = progressPercentage(xp)
		
		return {
			type = 'LEVEL_OVERVIEW',
			payload = stats
		}
	end
end

return levelSys