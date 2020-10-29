local tbl = {}

--[[
Flip the table's keys with its values
@param source The table you want to flip
@param mergeDupes Merge key duplicates into a table instead of overwriting them
]]
tbl.flip = function(source, mergeDupes)
	local res = {}
	local dupes = {}
	
	for k, v in pairs(source) do
		if res[v] == nil then
			res[v] = k
		elseif mergeDupes then
			if not dupes[v] then
				dupes[v] = { k }
				res[v] = dupes[v] -- Memory reference
			else
				dupes[v][#dupes[v] + 1] = k
			end
		end
	end
	
	return res
end

-- https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Array/map
tbl.map = function(source, filterFn)
	local res = {}
	
	--[[for i, v in ipairs(source) do
		res[#res + 1] = filterFn(v, i) or v
	end]]
	
	for k, v in pairs(source) do -- Order not guaranteed
		local index, value = #res + 1, v
		
		if filterFn then
			local fnVal, fnKey = filterFn(v, k)
			
			if fnKey ~= nil then
				index = fnKey
			end
			
			value = fnVal
		end
		
		res[index] = value
	end
	
	return res
end

-- Map an object by index
tbl.mapIndex = function(source, fn)
	local res = {}
	
	for i, v in ipairs(source) do
		local index, value = #res + 1, v
		
		if fn then
			local fnVal, fnKey = fn(v, i)
			
			if fnKey then
				index = fnKey
			end
			
			if fnVal ~= nil then
				value = fnVal
			end
		end
		
		res[index] = value
	end
	
	return res
end

-- assert(table.concat('111, 222, 333', ',') == '111, 222, 333')
tbl.split = function(str, sep, trim)
	if not str then
		return {}
	elseif not sep then
		sep = ' '
	end
	
	str = tostring(str)
	
	local chunks = {}
	
	if not trim and str:sub(0, 1) == sep then
		chunks[1] = ''
	end
	
	str:gsub('([^' .. sep .. ']+)', function(x)
		chunks[#chunks + 1] = x
	end)
	
	if not trim and str:sub(-1, -1) == sep then
		chunks[#chunks + 1] = ''
	end
	
	return chunks
end
--[[
-- Todo: add nested merge
tbl.merge = function(to, from) -- Merges to the first given table
	assert(typeof(to) == 'table', 'First argument must be a table')
	assert(typeof(from) == 'table', 'Second argument must be a table')
	
	for k, v in pairs(from) do
		to[k] = v
	end
end]]

tbl.join = function(obj, separator)
	local res = ''
	
	for i, v in ipairs(obj) do
		if typeof(v) == 'string' or typeof(v) == 'number' then
			res = res .. (i == #obj and v or v .. separator)
		end
	end
	
	return res
end

tbl.extend = function(to, from)
	assert(typeof(to) == 'table', 'First argument must be a table')
	assert(typeof(from) == 'table', 'Second argument must be a table')
	
	for k, v in pairs(from) do
		to[k] = v
	end
	
	return to
end

tbl.treePath = function(tree, str, divider)
	local res = tree
	
	for _, childName in pairs(tbl.split(str, divider or '.', true)) do
		if (typeof(res) ~= 'Instance' and res[childName]) or (typeof(res) == 'Instance' and res:FindFirstChild(childName)) then
			res = res[childName]
		else
			return nil
		end
	end
	
	return res
end

tbl.insertIf = function(to, bool, value)
	assert(typeof(to) == 'table', 'Table is missing')
	
	if bool then
		to[#to + 1] = value
	end
end

tbl.tableRemove = function(obj, removeTest)
	 -- Convert to a test function if the test value is a number or table
	local test
	
	if typeof(removeTest) == 'number' then
		test = function(value, newIndex, i)
			return i == removeTest
		end
	elseif typeof(removeTest) == 'table' then
		test = function(value, newIndex, i)
			for _, v in ipairs(removeTest) do
				return value == v
			end
		end
	end
	
	local newIndex = 1
	
	for i, value in ipairs(obj) do
		if not test(value, newIndex, i) then
			if i ~= newIndex then
				obj[newIndex] = obj[i] -- Move to new index
				obj[i] = nil -- Delete from old index
			end
			
			newIndex = newIndex + 1 -- Increment index
		else
			obj[i] = nil
		end
	end
end

tbl.modelToTable = function(model)
	assert(model, 'tbl.modelToTable - Missing model object')
	
	local obj = {}
	
	for _, v in pairs(model:GetChildren()) do
		if v ~= script then
			obj[v.Name] = v
		end
	end
	
	return obj
end

local valueClasses = {
	BoolValue = true;
	BrickColorValue = true;
	CFrameValue = true;
	Color3Value = true;
	IntValue = true;
	NumberValue = true;
	ObjectValue = true;
	RayValue = true;
	StringValue = true;
	Vector3Value = true;
}

tbl.tableLength = function(obj)
	assert(obj, 'tbl.tableLength - Missing object')
	
	local res = 0
	
	for _, v in pairs(obj) do
		res = res + 1
	end
	
	return res
end

tbl.tableRandomIndex = function(obj)
	assert(obj, 'tbl.tableRandomIndex - Missing object')
	assert(typeof(obj) == 'table' or typeof(obj) == 'Instance', 'tbl.tableRandomIndex - Cannot index ' .. typeof(obj))
	
	obj = typeof(obj) == 'Instance' and obj:GetChildren() or obj
	
	local indexes = {}
	
	-- Map all children names and indexes into a table
	for k, _ in pairs(obj) do
		indexes[#indexes + 1] = k
	end
	
	return #indexes > 0 and indexes[math.random(1, #indexes)] or nil
end

tbl.indexOf = function(obj, value)
	assert(obj, 'tbl.indexOf - Missing object')
	assert(typeof(obj) == 'table', 'tbl.indexOf - Cannot index ' .. typeof(obj))
	
	for k, v in pairs(obj) do
		if v == value then
			return k
		end
	end
end

tbl.tableRandom = function(obj)
	assert(obj, 'tbl.tableRandom - Missing object')
	assert(typeof(obj) == 'table' or typeof(obj) == 'Instance', 'tbl.tableRandomIndex - Cannot index ' .. typeof(obj))
	
	obj = typeof(obj) == 'Instance' and obj:GetChildren() or obj
	
	return obj[tbl.tableRandomIndex(obj)]
end

-- Makes a nested tree of the folder
-- Best used for configuration folders with a lot of values
tbl.makeConfig = function(folder)
	local res = {}
	
	for _, obj in pairs(folder:GetChildren()) do
		if obj:IsA('Folder') or obj:IsA('Configuration') then -- Nest
			res[obj.Name] = tbl.makeConfig(obj)
		elseif valueClasses[obj.ClassName] then
			res[obj.Name] = obj.Value
		else --elseif configClasses[el.ClassName] then
			res[obj.Name] = obj
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