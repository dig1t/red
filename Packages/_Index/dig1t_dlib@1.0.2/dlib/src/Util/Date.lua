local date = {}

date.unix = function()
	return string.gsub(tostring(os.clock()), '%.', '')
end

date.timeAgo = function(timestamp)
	assert(typeof(timestamp) == 'number', 'Timestamp must be a number')
	
	return date.unix() - timestamp
end

date.getMinutes = function(timestamp)
	assert(typeof(timestamp) == 'number', 'Timestamp must be a number')
	
	return math.floor(timestamp / 60)
end

date.getSeconds = function(timestamp)
	assert(typeof(timestamp) == 'number', 'Timestamp must be a number')
	
	if timestamp / 60 == math.floor(timestamp / 60) then
		return 0
	end
	
	return timestamp - (60 * math.floor(timestamp / 60))
end

date.unixToClockFormat = function(timestamp) -- TODO: add support for hours and milliseconds
	assert(typeof(timestamp) == 'number', 'Timestamp must be a number')
	
	local minutes = tostring(date.getMinutes(timestamp))
	local seconds = tostring(date.getSeconds(timestamp))
	
	return string.format(
		'%s:%s',
		string.len(minutes) == 1 and ('0' .. minutes) or minutes,
		string.len(seconds) == 1 and ('0' .. seconds) or seconds
	)
end

-- TODO date.timeAgo(timestamp, optional endTimestamp) - returns in format 1 month 2 days 1 hour 40 minutes 10 seconds

return date