-- src/ReplicatedStorage/red/UtilModules/Date.lua

local date = {}

date.unix = function()
	return string.gsub(tostring(tick()), '%.', '')
end

date.getMinutes = function(timestamp)
	return math.floor(timestamp / 60)
end

date.getSeconds = function(timestamp)
	if timestamp / 60 == math.floor(timestamp / 60) then return 0 end
	return timestamp - (60 * math.floor(timestamp / 60))
end

date.unixToClockFormat = function(timestamp, zero)
	local minutes = date.getMinutes(timestamp)
	local seconds = date.getSeconds(timestamp)
	
	if zero and string.len(seconds) == 1 then seconds = '0'..seconds end
	if zero and string.len(minutes) == 1 then minutes = '0'..minutes end
	
	return minutes..':'..seconds
end

return date