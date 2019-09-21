-- src/ReplicatedStorage/red/UtilModules/Search.lua

local search = {}
local searchParts = 0
local parts = {
	Part = true,
	CornerWedgePart = true,
	MeshPart = true,
	TrussPart = true,
	WedgePart = true,
	UnionOperation = true,
	Seat = true,
	VehicleSeat = true,
	SpawnLocation = true
}

search.isPart = function(obj)
	return obj and obj.ClassName and parts[obj.ClassName]
end

search.getChildCount = function(obj)
	if not obj then
		return
	end
	
	for k, v in pairs(obj:GetChildren()) do
		table.insert(searchParts, v)
		
		if #v:GetChildren() > 0 then
			search.getChildCount(v)
		end
	end
end

search.searchForParts = function(obj)
	if not obj then
		return
	end
	
	for k, v in pairs(obj:GetChildren()) do
		if search.isPart(v) then
			table.insert(searchParts, v)
		end
		
		if #v:GetChildren() > 0 then
			search.searchForParts(v)
		end
	end
end

search.getDescendantCount = function(obj)
	if not obj then
		return
	end
	
	searchParts = {}
	search.searchForParts(obj)
	return #searchParts
end

search.getDescendantParts = function(obj)
	if not obj then
		return
	end
	
	searchParts = {}
	search.searchForParts(obj)
	return searchParts
end

search.getAncestor = function(child, condition)
	if not child or not condition then
		return
	end
	
	if type(condition) == 'string' then
		local search = condition
		
		condition = function(obj)
			return obj and obj.Name == search
		end
	end
	
	while child do
		if condition(child) then
			return child
		else
			child = child.Parent
		end
	end
end

search.find = function(parent, condition, maxRounds, round)
	if not parent or not condition then
		return
	end
	
	if not round then
		round = 1
	end
	
	if type(condition) == 'string' then
		local search = condition
		
		condition = function(obj)
			return obj and obj.Name == search
		end
	end
	
	local match
	local nextBatch = {}
	
	-- search all children first - first round
	for k, child in pairs(parent:GetChildren()) do
		if condition(child) then
			match = child
			break
		elseif #child:GetChildren() > 0 then
			table.insert(nextBatch, child)
		end
	end
	
	if not match and round >= maxRounds then
		return
	end
	
	-- search grandchildren after - second round
	if not match then
		for k, child in pairs(nextBatch) do
			match = search.find(child, condition, maxRounds, round + 1)
		end
	end
	
	return match
end

search.exists = function(obj, e)
	if not obj then
		return
	end
	
	if type(e) == 'string' then
		return obj:FindFirstChild(e)
	elseif type(e) == 'table' then
		for k, v in pairs(e) do
			if not obj:FindFirstChild(v) then
				return false
			end
		end
		
		return true
	end
end

search.getFirstPart = function(model)
	local children = type(model) == 'table' and model or model:GetChildren()
	local i = 1
	
	while i < (#children) and not search.isPart(children[i]) do
		i = i + 1
	end
	
	return children[i]
end

return search