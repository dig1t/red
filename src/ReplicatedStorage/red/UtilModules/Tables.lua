-- src/ReplicatedStorage/red/UtilModules/Tables.lua

local tbl = {}

tbl.split = function(str, delimiter)
	local chunks = {}
	
	for substring in str:gmatch('%S+') do
		table.insert(chunks, substring)
	end
	
	return chunks
end

-- Todo: add nested merge
tbl.merge = function(a, b) -- Merges to the first given table
	if (
		assert(type(a) == 'table', 'First argument must be a table') and
		assert(type(b) == 'table', 'Second argument must be a table')
	) then
		for k, v in pairs(b) do
			a[k] = v
		end
	end
end

tbl.extend = function(to, from)
	for k, v in pairs(from) do
		to[k] = v
	end
	
	return to
end

tbl.modelToTable = function(model)
	local obj = {}
	
	for k, v in pairs(model:GetChildren()) do
		if v ~= script then
			obj[v.Name] = v
		end
	end
	
	return obj
end

local valueClasses = {
	BoolValue = true,
	BrickColorValue = true,
	CFrameValue = true,
	Color3Value = true,
	IntValue = true,
	NumberValue = true,
	ObjectValue = true,
	RayValue = true,
	StringValue = true,
	Vector3Value = true,
}

tbl.folderToTable = function(folder)
	local res = {}
	
	for i, v in pairs(folder:GetChildren()) do
		if v:IsA('Folder') or v:IsA('Configuration') then
			res[v.Name] = tbl.folderToTable(v)
		end
		
		if valueClasses[v.className] then
			res[v.Name] = v.Value
		end
	end
	
	return res
end

-- Create instances from a nested table
tbl.makeNestLoop = function(name, data, parent)
	local context = Instance.new(data.class, parent)
	context.Name = name
	
	if data.value then
		context.Value = data.value
	end
	
	if data.properties then
		for k, v in pairs(data.properties) do
			pcall(function()
				context[k] = v
			end)
		end
	end
	
	for k, v in pairs(data) do
		if type(v) == 'table' then
			tbl.makeNestLoop(k, v, context)
		end
	end
	
	if not parent then
		return context -- return to initial call
	end
end

tbl.makeNest = function(name, data)
	return tbl.makeNestLoop(name, data)
end

return tbl