--[[
@name Part Exploder
@desc Breaks blocks and throws its fragments in it's forward face
@author dig1t
]]

local Workspace = game:GetService('Workspace')
local Physics = game:GetService('PhysicsService')

local dLib = require(script.Parent)
local Util = dLib.import('Util')

local PLAYER_COLLISION_GROUP_NAME = 'Player'
local PROPS_COLLISION_GROUP_NAME = 'Props'
local COLLIDABLE = false -- Players cannot interact with these objects

local methods = {}
methods.__index = methods

-- Insert collision groups if missing
if not COLLIDABLE then
	local playerGroupExists
	local propGroupExists
	
	for _, group in pairs(Physics:GetCollisionGroups()) do
		if group.name == PLAYER_COLLISION_GROUP_NAME then
			playerGroupExists = true
		elseif group.name == PROPS_COLLISION_GROUP_NAME then
			propGroupExists = true
		end
	end
	
	if not playerGroupExists then
		Physics:CreateCollisionGroup(PLAYER_COLLISION_GROUP_NAME)
	end
	
	if not propGroupExists then
		Physics:CreateCollisionGroup(PROPS_COLLISION_GROUP_NAME)
	end
	
	if not playerGroupExists or not propGroupExists then
		-- Disable collisions with ragdoll characters
		Physics:CollisionGroupSetCollidable(
			PLAYER_COLLISION_GROUP_NAME,
			PROPS_COLLISION_GROUP_NAME,
			false
		)
	end
end

function methods:_breakPart(part)
	local partMagnitude = 0
	
	repeat
		local fragment = part:Clone()
		
		if not COLLIDABLE then
			-- Disable player collision
			Physics:SetPartCollisionGroup(fragment, PROPS_COLLISION_GROUP_NAME)
		end
		
		fragment:ClearAllChildren() -- Remove welds, effects, etc.
		
		fragment.Anchored = false
		fragment.CanCollide = true
		
		local newPosition = part.CFrame:ToWorldSpace(CFrame.new(
			math.random(-part.Size.X * 10, part.Size.X * 10) / 10 / 2,
			math.random(-part.Size.Y * 10, part.Size.Y * 10) / 10 / 2,
			math.random(-part.Size.Z * 10, part.Size.Z * 10) / 10 / 2
		))
		
		fragment.CFrame = newPosition + (fragment.CFrame.LookVector * 1.2)
		
		fragment.Size = Vector3.new(
			part.Size.X / (math.random(4, 8) / 1.2),
			part.Size.Y / (math.random(4, 8) / 1.2),
			part.Size.Z / (math.random(4, 8) / 1.2)
		)
		
		if self.config.throw then
			local attachment = Instance.new('Attachment')
			attachment.Name = 'GlassAttachment'
			attachment.Position = fragment.CFrame:ToObjectSpace(
				newPosition + (fragment.CFrame.LookVector * 4)
			).Position
			attachment.Parent = fragment
			
			local force = Instance.new('VectorForce')
			force.Force = fragment.CFrame:ToObjectSpace(
				newPosition + (fragment.CFrame.LookVector * 40)
			).Position
			force.Attachment0 = attachment
			force.Parent = fragment
		end
		
		partMagnitude += fragment.Size.Magnitude
		
		self.fragments[#self.fragments + 1] = fragment
		fragment.Parent = self.config.parent or Workspace
	until partMagnitude > part.Size.Magnitude * 3
	
	part:Destroy()
	
	return nil
end

function methods:destroy()
	for _, fragment in pairs(self.fragments) do
		if fragment.Parent then
			fragment:Destroy()
		end
	end
	
	self.fragments = nil
	
	return nil
end

--[[
@param part BasePart|table part or list of parts to destroy
@param config table Explosion modifications
	{
		clean = true; -- Remove fragments after a set amount of time (cleanTime) 
		cleanTime = 8; -- Time until fragments are removed
		throw = true; -- Throws fragments forward
		parent = Workspace -- Where fragments are placed in the World object
	}
]]
return function(part, config)
	assert(typeof(part) == 'Instance' and part:IsA('BasePart') or typeof(part) == 'table', 'Missing part(s) to break')
	
	local self = setmetatable({}, methods)
	
	self.config = typeof(config or nil) == 'table' and config or {
		clean = true;
		cleanTime = 1;
		throw = true;
	}
	self.fragments = {}
	
	coroutine.wrap(function()
		for _, obj in pairs(
			typeof(obj) == 'Instance' and { obj } or obj
		) do
			if typeof(obj) == 'Instance' and part:IsA('BasePart') then
				coroutine.wrap(function()
					self:_breakPart(obj)
				end)()
			end
		end
		
		Util.yield(.85)
		
		if self.config.throw then
			for _, fragment in pairs(self.fragments) do
				if fragment.Parent then
					fragment:ClearAllChildren()
				end
			end
		end
		
		Util.yield(self.config.cleanTime or 8)
		
		if self.config.clean and self.fragments then
			self:destroy()
		else
			for _, fragment in pairs(self.fragments) do
				if fragment.Parent then
					-- Remove remaining moving parts
					if fragment.Velocity.Magnitude > .001 then
						fragment:Destroy()
					end
					
					fragment.Anchored = true
				end
			end
		end
	end)()
	
	return self
end