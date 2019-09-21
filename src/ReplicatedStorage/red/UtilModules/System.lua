-- src/ReplicatedStorage/red/UtilModules/System.lua

local sys = {}

sys.print = function(str)
	print(str)
end

sys.error = function(err)
	error('Error: '..err, 0)
end

sys.warn = function(str)
	error('Error: '..str, 0)
end

sys.inTable = function(obj, e)
	if not obj then
		return
	end
	
	if type(e) == 'table' then
		local i = 0
		
		for k, v in pairs(e) do
			i = i + 1
			
			if k ~= i then
				if not obj[k] then
					return false
				end
			else
				if not obj[v] then
					return false
				end
			end
		end
		
		return true
	else
		for k, v in pairs(obj) do
			if v == e then
				return true
			end
		end
		
		return false
	end
end

return sys