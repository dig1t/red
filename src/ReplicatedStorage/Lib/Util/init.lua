local Util = {}

setmetatable({}, {
	__index = Util,
	__call = function (class, ...)
		return class.instance(...)
	end
})

Util.use = function(obj)
	if type(obj) == 'string' then
		if script:FindFirstChild(obj) then
			obj = require(script[obj])
		elseif script.Parent:FindFirstChild(obj) then
			obj = require(script.Parent[obj])
		end
	elseif typeof(obj) == 'userdata' and obj.ClassName == 'ModuleScript' then
		obj = require(obj)
	else
		error('Could not load module: ', obj)
	end
	
	for k, v in pairs(obj) do
		Util[k] = v
	end
end

-- Import modules
Util.use('Date')
Util.use('Math')
Util.use('Players')
Util.use('Search')
Util.use('System')
Util.use('Tables')

Util.asset = 'rbxassetid://'
Util.firebitLogo = 'rbxassetid://4904946138'
Util.defaultWalkSpeed = 16

Util.instance = function(className, ...)
	local props = {}
	local extraProps = {...}
	
	for i = 1, #extraProps do
		if type(extraProps[i]) == 'table' then
			for name, value in pairs(extraProps[i]) do
				props[name] = value
			end
		end
	end
	
	return function(data)
		local obj = Instance.new(className)
		
		if data then
			Util.extend(props, data)
			
			if props.children then
				for _, child in pairs(props.children) do
					if type(child) == 'function' then
						child = child()
					end
					
					child.Parent = obj
				end
				
				props.children = nil
			end
			
			for prop, value in pairs(props) do
				if type(prop) == 'number' then -- Instance?
					if type(value) == 'function' then
						value = value()
					end
					
					value.Parent = obj
				elseif prop ~= 'Parent' then -- Apply properties
					obj[prop] = value
				end
			end
			
			if props.Parent then
				obj.Parent = props.Parent -- Always set parent last
			end
		end
		
		return obj
	end
end

local valueObjects = {
	'ObjectValue', 'StringValue', 'NumberValue', 'BoolValue', 'CFrameValue', 'Vector3Value', 'Color3Value', 'BrickColorValue'
}

Util.get = function(path, parent) -- expiremental
	local res = parent
	
	--local success, err = pcall(function()
		local chunks = Util.split(path, '.')
		
		if not chunks then
			return
		end
		
		res = res or (chunks[1] == 'game' and game or game[chunks[1]])
		
		table.remove(chunks, 1)
		
		for _, child in pairs(chunks) do
			res = res[child]
		end
		--[[
		for child in chunks do
			res = res[child]
		end]]
	--end)
	
	--if not success then
		--warn(err)
	--end
	
	return res ~= nil and Util.indexOf(valueObjects, res.ClassName) and res.Value or res -- success and res
end

Util.set = function(parent, name, value) -- Tool to set value instances
	local valueType = typeof(value)
	
	if valueType == 'table' then
		valueType = 'ObjectValue'
	elseif valueType == 'string' then
		valueType = 'StringValue'
	elseif valueType == 'number' then
		valueType = 'NumberValue'
	elseif valueType == 'boolean' then
		valueType = 'BoolValue'
	elseif valueType == 'CFrame' then
		valueType = 'CFrameValue'
	elseif valueType == 'Vector3' then
		valueType = 'Vector3Value'
	elseif valueType == 'Color3' then
		valueType = 'Color3Value'
	elseif valueType == 'BrickColor' then
		valueType = 'BrickColorValue'
	end
	
	local valueObject
	
	pcall(function()
		if not parent:FindFirstChild(name) then
			valueObject = Instance.new(valueType)
			valueObject.Name = name
			valueObject.Parent = parent
		else
			valueObject = parent[name]
		end
		
		valueObject.Value = value
	end)
	
	return valueObject
end

Util.printTable = function(tbl)
	print(tbl and game:GetService('HttpService'):JSONEncode(tbl))
end

-- Calls the given function until it successfully runs
-- Used for retrieving from a DataStore or GET/POST requests
Util.attempt = function(fn, maxTries, yield)
	local res
	local successful = false
	local tries = 0
	
	repeat
		local success, returned = pcall(fn)
		
		if success then
			res = returned
			successful = true
		end
		
		tries = tries + 1
		
		if not successful then -- or tries <= (maxTries or 3) then
			Util.yield(yield or 1)
		end
	until successful or tries > (maxTries or 3)
	
	return successful, res, tries
end

Util.try = function(fn, catch)
	local success, err = pcall(fn)
	
	if not success then
		catch(err)
	end
end

-- Parts

--[[
	- @desc welds 2 parts
]]--
Util.weld = function(part, attachTo, offset)
	if not part or not part.Parent or not attachTo or not attachTo.Parent then
		return
	end
	
	if offset then
		part.CFrame = attachTo.CFrame * offset
	end
	
	return Util.instance('WeldConstraint') {
		Part0 = part;
		Part1 = attachTo;
		Parent = part;
	}
end

-- Models

Util.getModelBounds = function(model)
	return model and model:IsA('Model') and model:GetBoundingBox()
end

Util.getMass = function(model)
	if not model or not model:IsA('Model') then
		return
	end
	
	local mass = 0
	
	for _, part in pairs(Util.getDescendantParts(model)) do
		mass = part:GetMass() + mass
	end
	
	return mass
end

Util.rotateModel = function(model, angle)
	local rotate = CFrame.fromEulerAnglesXYZ(0, angle, 0)
	
	for i, object in pairs(model:GetChildren()) do
		if object:IsA('BasePart') then
			object.CFrame = rotate * object.CFrame
		end
	end
end

Util.moveModel = function(model, to)
	local firstPart = Util.getFirstPart(model)
	
	if firstPart then
		local origin = firstPart.CFrame.p
		
		for i, object in pairs(model:GetChildren()) do
			if object:IsA('BasePart') then
				local newPositionInWorld = object.Position - origin + to.p
				local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = object.CFrame:components()
				
				object.CFrame = CFrame.new(newPositionInWorld.x, newPositionInWorld.y, newPositionInWorld.z, R00, R01, R02, R10, R11, R12, R20, R21, R22)
			end
		end
	end
end

-- Events

Util.addEventListener = function(obj, event, fn)
	return obj.Changed:Connect(function(e)
		if e == event then
			fn()
		end
	end)
end

local ON_TOUCH_OFFSET = 4

-- onTouch will increase the likelyhood that
-- players get detected when walking on a part
-- by placing a clone of the part above the part
Util.onTouch = function(obj, fn)
	local detector = obj:Clone()
	detector.Name = 'Detector'
	detector.Transparency = 1
	detector.Size = Vector3.new(detector.Size.X, ON_TOUCH_OFFSET, detector.Size.Z)
	detector.CFrame = obj.CFrame:ToWorldSpace(CFrame.new(0, (ON_TOUCH_OFFSET / 2) + (obj.Size.Y / 2), 0)) -- Place on top of the current part, then offset by half of ON_TOUCH_OFFSET
	detector.CanCollide = false
	detector.Parent = obj
	
	if not obj.Anchored then
		Util.weld(detector, obj)
	end
	
	return detector.Touched:Connect(fn)
end

Util.onPlayerTouch = function(obj, fn, ignoreIfDead, offsetPart)
	local callback = function(part)
		local player = Util.getPlayerFromPart(part)
		
		if player then
			local alive = Util.isAlive(player)
			
			if alive or (not alive and ignoreIfDead) then
				fn(player, part)
			end
		end
	end
	
	return offsetPart and Util.onTouch(obj, callback) or obj.Touched:Connect(callback)
end

return Util