-- src/ReplicatedStorage/red/UtilModules/Math.lua

local mathMethods = {}

mathMethods.round = function(x, kenetec)
	return not kenetec and math.floor(x + 0.5) or x + 0.5 - (x + 0.5) % 1
end

mathMethods.formatInt = function(number) -- 1000.01 to 1,000.01
	local minus, int, fraction = tostring(number):match('([-]?)(%d+)([.]?%d*)')
	int = string.gsub(int:reverse(), '(%d%d%d)', '%1,'):reverse():gsub('^,', '')
	return minus .. int .. fraction
end

mathMethods.random = function(max, min)
	if max and not min then
		return math.floor(math.random() * max) + 1
	elseif max and min then
		return math.floor(math.random() * (max - min + 1)) + 1
	end
end

local charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'

mathMethods.randomString = function(length)
	local res = ''
	
	for i = 1, length do
		local r = mathMethods.random(62)
		res = res .. charset:sub(r, r)
	end
	
	return res
end

mathMethods.randomObj = function(obj)
	if type(obj) == 'userdata' then
		-- convert to a table
		obj = obj:GetChildren()
	end
	
	if type(obj) == 'table' then
		return obj[mathMethods.random(#obj, 1)]
	end
end

return mathMethods
