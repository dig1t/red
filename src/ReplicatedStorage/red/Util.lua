-- src/ReplicatedStorage/red/Util.lua

local _ = {}

setmetatable(_, {
	__index = _,
	
	__call = function (class, ...)
		return class.query(...)
	end
})

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
		error('Could not load module: ', obj)
		return
	end
	
	for k, v in pairs(obj) do
		_[k] = v
	end
end

_.use('Date')
_.use('Math')
_.use('Players')
_.use('Search')
_.use('System')
_.use('Tables')

_.assetURL = 'rbxassetid://'

_.minTransparencySeeThru = .25 -- Minimum camera distance until character becomes transparent

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
	--
	['GuiObject::BackgroundColor'] = true; -- Redundant with BackgroundColor3
	['GuiObject::BorderColor'] = true; -- BorderColor3
}
]]

function _.query(config)
	local obj = Instance.new(config.class or config.Class or 'Part')
	
	-- TODO LINE 41
	for k, v in pairs(config) do
		local success, err = pcall(function()
			obj[k] = v
		end)
		
		-- if err then print(err) end
	end
	
	-- Shortcuts
	if config.name then obj.Name = config.name end
	
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
		obj.Scale = config.scale
	end
	
	-- mesh
	if config.mesh then
		local mesh = Instance.new(config.meshType, obj)
		if config.meshId then mesh.MeshId = _.assetURL .. config.meshID end
		if config.meshSpecialType then mesh.MeshType = config.meshSpecialType end
		if config.offset then mesh.Offset = config.offset end
		if config.meshScale then mesh.Scale = config.meshScale end
		if config.meshTexture then mesh.TextureId = _.assetURL .. config.meshTexture end
		if config.meshColor then mesh.VertexColor = config.meshColor end
	else
		if config.meshID then obj.MeshId = _.assetURL .. config.meshID end
		if config.meshType then obj.MeshType = config.meshType end
		if config.meshTexture then obj.TextureId = _.assetURL .. config.meshTexture end
		if config.meshScale then obj.Scale = config.meshScale end
		if config.meshColor then obj.VertexColor = config.meshColor end
		if config.offset then obj.Offset = config.offset end
	end
	
	if config.parent then obj.Parent = config.parent end
	
	return obj
end

--

_.attempt = function(fn, maxTries, yield)
	local res
	local successful = false
	local tries = 0
	
	repeat
		local success, returned = yield and ypcall(fn) or pcall(fn)
		
		if success then
			res = returned
			successful = true
		end
		
		tries = tries + 1
		
		if yield then
			wait(yield)
		end
	until maxTries >= tries or successful
	
	return successful, res, tries
end

-- Parts

--[[
	- @desc welds 2 parts
	- @param table config - configuration of the weld (obj, attachTo, C0, C1, angle0, angle1, parent)
]]--
_.weld = function(cfg)
	if not cfg.obj or not cfg.attachTo then return end
	
	if not cfg.C0 then
		cfg.C0 = CFrame.new(0, 0, 0)
	end
	
	if cfg.angle0 then
		cfg.C0 = cfg.C0 * cfg.angle0
	end
	
	if cfg.angle1 then
		cfg.C1 = cfg.C1 * cfg.angle1
	end
	
	local weld = _({
		class = 'Weld',
		Part0 = cfg.obj,
		Part1 = cfg.attachTo,
		C0 = cfg.C0,
		C1 = cfg.C1
	})
	
	if cfg.parent then
		weld.Parent = cfg.parent
	else
		weld.Parent = cfg.obj
	end
	
	return weld
end

-- Models

_.getModelBounds = function(model)
	return model and model:IsA('Model') and model:GetBoundingBox()
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

-- Events

_.addEventListener = function(obj, change, fn)
	obj.Changed:Connect(function(event)
		if event == change then
			fn()
		end
	end)
end

_.onPlayerTouch = function(obj, fn, ignoreIfDead)
	obj.Touched:Connect(function(part)
		local player = _.getPlayerFromPart(part)
		
		if player and (not ignoreIfDead and _.isAlive(player)) then
			fn(player, part)
		end
	end)
end

return _