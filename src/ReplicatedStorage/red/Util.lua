local _ = {}

setmetatable(_, {
	__index = _,
	
	__call = function (class, ...)
		return class.query(...)
	end
})

_.assetURL = 'rbxassetid://'

_.minTransparencySeeThru = .25 -- minimum camera distance until character becomes transparent

--[[
-- Derived properties to ignore as they are redundant with another property
local IgnorePropSet = {
	['BasePart::CFrame'] = true; -- use position + rotation pairs
	--['BasePart::Rotation'] = true;
	--['BasePart::Position'] = true;
	['BasePart::Color'] = true;  -- Redundant with BrickColor
	['GuiObject::Transparency'] = true; -- Redandant with other transparencies
	['Tool::GripUp']      = true; -- Redundant with Tool::Grip
	['Tool::GripRight']   = true;
	['Tool::GripForward'] = true;
	['Tool::GripPos']     = true;
	['Instance::Parent'] = true;     -- Is inherent from data structuring
	['Instance::ClassName'] = true;  -- Needs special encoding
	--
	['GuiObject::BackgroundColor'] = true; -- Redundant with BackgroundColor3
	['GuiObject::BorderColor'] = true; -- BorderColor3
}
]]

function _.query(config)
	local obj = Instance.new(config.class or 'Part')
	
	if config.Size then
		obj.FormFactor = Enum.FormFactor.Custom
	end
	
	-- TODO LINE 12
	for k, v in pairs(config) do
		local success, err = pcall(function()
			obj[k] = v
		end)
		
		--if err then print(err) end
	end
	
	-- Shortcuts
	if config.name then obj.Name = config.name end
	--[[if config.brickColor then obj.BrickColor = config.brickColor end
	if config.color then obj.Color = config.color end
	if config.position then obj.Position = config.position end
	if config.coords then obj.CFrame = config.coords end
	if config.rotation then obj.Rotation = config.rotation end
	if config.velocity then obj.Velocity = config.velocity end
	if config.rotationVelocity then obj.rotationVelocity = config.velocity end
	if config.anchored then obj.Anchored = config.anchored end
	if config.nonCollidable == true then obj.CanCollide = false end
	if config.locked then obj.Locked = config.locked end
	if config.material then obj.Material = config.material end
	if config.reflectance then obj.Reflectance = config.reflectance end
	if config.transparency then obj.Transparency = config.transparency end
	if config.elasticity then obj.Elasticity = config.elasticity end
	if config.friction then obj.Friction = config.friction end
	if config.shape then obj.Shape = config.shape end
	if config.bottomSurface then obj.BottomSurface = config.bottomSurface end
	if config.backSurface then obj.BackSurface = config.backSurface end
	if config.frontSurface then obj.FrontSurface = config.frontSurface end
	if config.leftSurface then obj.LeftSurface = config.leftSurface end
	if config.rightSurface then obj.RightSurface = config.rightSurface end
	if config.topSurface then obj.TopSurface = config.topSurface end]]
	
	if config.surface then -- set surface for all sides
		obj.BackSurface = config.surface
		obj.BottomSurface = config.surface
		obj.FrontSurface = config.surface
		obj.LeftSurface = config.surface
		obj.RightSurface = config.surface
		obj.TopSurface = config.surface
	end
	
	-- sound
	
	if config.scale then
		if _.isPart(obj) and (config.scale.X < 1 or config.scale.Y < 1 or config.scale.Z < 1) then
			obj.FormFactor = Enum.FormFactor.Custom
		end
		
		obj.Scale = config.scale
	end
	
	-- mesh
	if config.mesh then
		local mesh = Instance.new(config.meshType, obj)
		if config.meshId then mesh.MeshId = _.assetURL..config.meshID end
		if config.meshSpecialType then mesh.MeshType = config.meshSpecialType end
		if config.offset then mesh.Offset = config.offset end
		if config.meshScale then mesh.Scale = config.meshScale end
		if config.meshTexture then mesh.TextureId = _.assetURL..config.meshTexture end
		if config.meshColor then mesh.VertexColor = config.meshColor end
	else
		if config.meshID then obj.MeshId = _.assetURL..config.meshID end
		if config.meshType then obj.MeshType = config.meshType end
		if config.meshTexture then obj.TextureId = _.assetURL..config.meshTexture end
		if config.meshScale then obj.Scale = config.meshScale end
		if config.meshColor then obj.VertexColor = config.meshColor end
		if config.offset then obj.Offset = config.offset end
	end
	
	if config.parent then obj.Parent = config.parent end
	
	return obj
end

_.use = function(obj)
	if type(obj) == 'string' then
		if script:FindFirstChild(obj) then
			obj = require(script[obj])
		elseif script.Parent:FindFirstChild(obj) then
			obj = require(script.Parent[obj])
		end
	elseif typeof(obj) == 'userdata' and obj.ClassName == 'ModuleScript' then
		obj = require(obj)
	else
		_.error('Could not load module')
		return
	end
	
	_.extend(_, obj)
end

-- system functions

_.print = function(str)
	print(str)
end

_.error = function(err)
	error('Error: '..err, 0)
end

_.warn = function(str)
	error('Error: '..str, 0)
end

_.inTable = function(obj, e)
	if not obj then
		return
	end
	
	if type(e) ~= 'table' then
		for k, v in pairs(obj) do
			if v == e then
				return true
			end
		end
		
		return false
	elseif type(e) == 'table' then
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
	end
end

_.unix = function()
	return string.gsub(tostring(tick()), '%.', '')
	-- return tonumber(string.gsub(tostring(tick()), '%.', ''))
end

_.getMinutes = function(timestamp)
	return math.floor(timestamp / 60)
end

_.getSeconds = function(timestamp)
	if timestamp / 60 == math.floor(timestamp / 60) then return 0 end
	return timestamp - (60 * math.floor(timestamp / 60))
end

_.unixToClockFormat = function(timestamp, zero)
	local minutes = _.getMinutes(timestamp)
	local seconds = _.getSeconds(timestamp)
	
	if zero and string.len(seconds) == 1 then seconds = '0'..seconds end
	if zero and string.len(minutes) == 1 then minutes = '0'..minutes end
	
	return minutes..':'..seconds
end

_.round = function(x, kenetec)
	return not kenetec and math.floor(x + 0.5) or x + 0.5 - (x + 0.5) % 1
end

_.formatInt = function(number)
	local minus, int, fraction = tostring(number):match('([-]?)(%d+)([.]?%d*)')
	int = string.gsub(int:reverse(), '(%d%d%d)', '%1,'):reverse():gsub('^,', '')
	return minus .. int .. fraction
end

_.random = function(max, min)
	if max and not min then
		return math.floor(math.random() * max) + 1
	elseif max and min then
		return math.floor(math.random() * (max - min + 1)) + 1
	end
end

_.charset = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'

_.randomString = function(length)
	local res = ''
	
	for i = 1, length do
		local r = _.random(62)
		res = res .. _.charset:sub(r, r)
	end
	
	return res
end

_.randomObj = function(obj)
	if not obj then
		return
	end
	
	if type(obj) == 'userdata' then
		-- convert to a table
		obj = obj:GetChildren()
	end
	
	if type(obj) == 'table' then
		return obj[_.random(#obj, 1)]
	end
end

_.split = function(str, delimiter)
	local chunks = {}
	
	for substring in str:gmatch('%S+') do
		table.insert(chunks, substring)
	end
	
	return chunks
end

_.extend = function(to, from)
	for k, v in pairs(from) do
		to[k] = v
	end
	
	return to
end

_.attempt = function(fn, maxTries, yield)
	local res
	local successful = false
	local tries = 0
	
	repeat
		local success, returned = ypcall(fn)
		
		if success then
			res = returned
			successful = true
		end
		
		tries = tries + 1
		
		if yield then
			wait(yield)
		end
	until maxTries >= tries or successful
	
	return res, successful, tries
end

-- player functions

_.getHumanoid = function(obj)
	if not obj then
		return
	end
	
	local humanoid
	
	if obj:IsA('Player') then
		if obj.Character and obj.Character:FindFirstChild('Humanoid') then
			humanoid = obj.Character.Humanoid
		end
	elseif obj:IsA('Model') then
		for k, v in pairs(obj:GetChildren()) do
			if v:IsA('Humanoid') then
				humanoid = v
				break
			end
		end
	elseif obj:IsA('Humanoid') then
		humanoid = obj
	end
	
	return humanoid
end

_.isAlive = function(obj)
	local humanoid = _.getHumanoid(obj)
	
	if humanoid then
		return humanoid.Health ~= 0
	end
end

_.getTeam = function(player)
	if player:IsA('Player') then
		local team
		
		if game:FindFirstChild('Teams') then
			for k, v in pairs(game.Teams:GetChildren()) do
				if v.TeamColor == player.TeamColor then
					team = v.Name
				end
			end
		end
		
		return player.TeamColor, team or 'Undefined'
	end
end

_.getPlayerFromPart = function(part)
	if part and part.Parent then
		local player 
		
		player = game.Players:GetPlayerFromCharacter(part.Parent)
		
		if not player and part.Parent.Parent then
			player = game.Players:GetPlayerFromCharacter(part.Parent.Parent)
		end
		
		return player
	end
end

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

_.isPart = function(obj)
	return obj and obj.ClassName and parts[obj.ClassName]
end

-- world search functions

local searchParts = 0

_.getChildCount = function(obj)
	if not obj then
		return
	end
	
	for k, v in pairs(obj:GetChildren()) do
		table.insert(searchParts, v)
		
		if #v:GetChildren() > 0 then
			_.getChildCount(v)
		end
	end
end

_.searchForParts = function(obj)
	if not obj then
		return
	end
	
	for k, v in pairs(obj:GetChildren()) do
		if _.isPart(v) then
			table.insert(searchParts, v)
		end
		
		if #v:GetChildren() > 0 then
			_.searchForParts(v)
		end
	end
end

_.getDescendantCount = function(obj)
	if not obj then
		return
	end
	
	searchParts = {}
	_.searchForParts(obj)
	return #searchParts
end

_.getDescendantParts = function(obj)
	if not obj then
		return
	end
	
	searchParts = {}
	_.searchForParts(obj)
	return searchParts
end

_.getAncestor = function(child, condition)
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

_.find = function(parent, condition, maxRounds, round)
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
			match = _.find(child, condition, maxRounds, round + 1)
		end
	end
	
	return match
end

_.exists = function(obj, e)
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

_.getFirstPart = function(model)
	local children = type(model) == 'table' and model or model:GetChildren()
	local i = 1
	
	while i < (#children) and not _.isPart(children[i]) do
		i = i + 1
	end
	
	return children[i]
end

-- model functions

_.getModelBounds = function(model)
	if not model or not model:IsA('Model') then
		return
	end
	
	return model:GetBoundingBox()
end

_.rotateModel = function(model, angle)
	local rotate = CFrame.fromEulerAnglesXYZ(0, angle, 0)
	
	for i, object in pairs(model:GetChildren()) do
		if _.isPart(object) then
			object.CFrame = rotate * object.CFrame
		end
	end
end

_.moveModel = function(model, to)
	local firstPart = _.getFirstPart(model)
	
	if firstPart then
		local reference = firstPart.CFrame.p
		
		for i, object in pairs(model:GetChildren()) do
			if _.isPart(object) then
				local positionInWorld = object.Position
				local newPositionInWorld = positionInWorld - reference + to.p
				
				local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = object.CFrame:components()
				
				object.CFrame = CFrame.new(newPositionInWorld.x, newPositionInWorld.y, newPositionInWorld.z, R00, R01, R02, R10, R11, R12, R20, R21, R22)
			end
		end
	end
end

_.modelToObject = function(model)
	local obj = {}
	
	for k, v in pairs(model:GetChildren()) do
		if v ~= script then
			obj[v.Name] = v
		end
	end
	
	return obj
end

local valueClasses = { 'BoolValue', 'BrickColorValue', 'CFrameValue', 'Color3Value', 'IntValue', 'NumberValue', 'ObjectValue', 'RayValue', 'StringValue', 'Vector3Value' }

_.folderToTable = function(folder)
	local result = {}
	
	for i, v in pairs(folder:GetChildren()) do
		if v:IsA('Folder') or v:IsA('Configuration') then
			result[v.Name] = _.folderToTable(v)
		end
		
		for i = 1, #valueClasses do
			if v:IsA(valueClasses[i]) then
				result[v.Name] = v.Value
			end
		end
	end
	
	return result
end

-- part functions

--[[
	- @desc welds 2 parts
	- @param table config - configuration of the weld (obj, attachTo, C0, C1, angle0, angle1, parent)
]]--
_.weld = function(config)
	if not config.obj then
		return
	end
	
	if not config.C0 then
		config.C0 = CFrame.new(0, 0, 0)
	end
	
	if config.angle0 then
		config.C0 = config.C0 * config.angle0
	end
	
	if config.angle1 then
		config.C1 = config.C1 * config.angle1
	end
	
	local weld = _({
		class = 'Weld',
		part0 = config.obj,
		part1 = config.attachTo,
		C0 = config.C0,
		C1 = config.C1
	})
	
	if config.parent then
		weld.Parent = config.parent
	else
		weld.Parent = config.obj
	end
	
	return weld
end

_.fade = function(obj, from, to, increment, interval)
	for i = from, to, increment or .1 do
		obj.BackgroundTransparency = i
		wait(interval or 0)
	end
end

-- create nested instances
_.makeNestLoop = function(name, data, parent)
	local context = Instance.new(data.class)
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
	
	if parent then
		context.Parent = parent
	end
	
	for k, v in pairs(data) do
		if type(v) == 'table' then
			_.makeNestLoop(k, v, context)
		end
	end
	
	if not parent then
		return context -- return to initial call
	end
end

_.makeNest = function(name, data)
	return _.makeNestLoop(name, data)
end

-- game functions

_.addEventListener = function(obj, change, func)
	obj.Changed:connect(function(event)
		if event == change then
			func()
		end
	end)
end

return _