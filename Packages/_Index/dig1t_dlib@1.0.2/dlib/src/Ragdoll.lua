--[[
@name Character Ragdoll
@author Digitalscape
]]

local Physics = game:GetService('PhysicsService')
local Workspace = game:GetService('Workspace')
local Debris = game:GetService('Debris')

local dLib = require(script.Parent)
local Util = dLib.import('Util')

local PLAYER_COLLISION_GROUP_NAME = 'Player'
local RAGDOLL_COLLISION_GROUP_NAME = 'Ragdoll'
local RAGDOLL_COLLIDABLE = true
local RAGDOLL_DESTROY_TIME = 5 -- Roblox default

-- Insert collision groups if missing
if not RAGDOLL_COLLIDABLE then
	local playerGroupExists
	local ragdollGroupExists
	
	for _, group in pairs(Physics:GetCollisionGroups()) do
		if group.name == PLAYER_COLLISION_GROUP_NAME then
			playerGroupExists = true
		elseif group.name == RAGDOLL_COLLISION_GROUP_NAME then
			ragdollGroupExists = true
		end
	end
	
	if not playerGroupExists then
		Physics:CreateCollisionGroup(PLAYER_COLLISION_GROUP_NAME)
	end
	
	if not ragdollGroupExists then
		Physics:CreateCollisionGroup(RAGDOLL_COLLISION_GROUP_NAME)
	end
	
	if not playerGroupExists or not ragdollGroupExists then
		-- Disable collisions with ragdoll characters
		Physics:CollisionGroupSetCollidable(PLAYER_COLLISION_GROUP_NAME, RAGDOLL_COLLISION_GROUP_NAME, false)
	end
end

local Ragdoll = {}

function Ragdoll.setup(character) -- Sets up the player's collision group
	local successful, humanoid, tries = Util.attempt(function()
		return character:FindFirstChild('Humanoid')
	end, 80, .1) -- 80 tries * .1 yield times = 8 second max yield
	
	if not humanoid then
		return
	end
	
	humanoid.BreakJointsOnDeath = false
	
	if not RAGDOLL_COLLIDABLE then
		for _, obj in pairs(character:GetDescendants()) do
			if obj:IsA('BasePart') then
				Physics:SetPartCollisionGroup(obj, PLAYER_COLLISION_GROUP_NAME)
			end
		end
	end
end

--[[
@desc Transforms a humanoid into a ragdoll
@param character - Character Model
]]
function Ragdoll.create(character)
	if not character or not character.Parent then
		return
	end
	
	local partAttachment = Util.instance('Attachment') {
		Parent = character:FindFirstChild('Head') or character.PrimaryPart or Util.getFirstPart(character);
	}
	
	-- Push player backwards
	if partAttachment.Parent then
		Util.instance('VectorForce') {
			--ApplyAtCenterOfMass = true;
			Force = Vector3.new(0, -200, 60);
			Attachment0 = partAttachment;
			Parent = partAttachment;
		}
	end
	
	for _, obj in pairs(character:GetDescendants()) do
		if obj:IsA('Motor6D') then
			local root = Instance.new('Attachment')
			local attachment = Instance.new('Attachment')
			root.CFrame = obj.C0
			root.Parent = obj.Part0
			attachment.CFrame = obj.C1
			attachment.Parent = obj.Part1
			
			local ballSocket = Instance.new('BallSocketConstraint')
			ballSocket.LimitsEnabled = true
			ballSocket.TwistLimitsEnabled = true -- Disable joints from freely rotating
			ballSocket.Attachment0 = root
			ballSocket.Attachment1 = attachment
			ballSocket.Parent = obj.Parent
			
			obj:Destroy() -- Remove the Motor6D instance
		end
		
		if obj:IsA('BasePart') then
			-- Switch collision group so players can't interact with the ragdoll
			obj.CanCollide = true
			
			if not RAGDOLL_COLLIDABLE then
				Physics:SetPartCollisionGroup(obj, RAGDOLL_COLLISION_GROUP_NAME)
			end
		elseif obj:IsA('Script') then
			obj:Destroy()
		end
	end
end

function Ragdoll.playerDied(player, parent, destroyTime, keepRagdollInWorld)
	if not player.Character then
		return
	end
	
	parent = parent or Workspace -- Default parent to Workspace
	
	local newCharacter = Instance.new('Model')
	newCharacter.Name = player.Character.Name
	newCharacter.Parent = parent
	
	-- Ragdolls automatically disappear after 2 minutes
	-- whether or not keepRagdollInWorld is enabled
	Debris:AddItem(newCharacter, 120)
	
	parent = newCharacter -- Assign parent as newCharacter
	
	Ragdoll.create(player.Character) -- Convert the player's character into a ragdoll
	
	if parent then
		-- Place parts inside the ragdoll model (newCharacter)
		-- and filter out unwanted instances and scripts
		for _, obj in pairs(player.Character:GetChildren()) do
			if obj.Name == 'OverheadDisplay' then
				obj:Destroy()
			elseif not obj:IsA('Tool') then
				obj.Parent = parent
			elseif obj:FindFirstChild('Handle') then
				obj.Handle.Parent = parent
				obj.Parent = player:FindFirstChild('Backpack')
			end
		end
	end
	
	player.Character:Destroy()
	player.Character = nil
	
	Util.yield(destroyTime or RAGDOLL_DESTROY_TIME)
	
	if not parent or not parent.Parent then
		return
	elseif not keepRagdollInWorld then
		parent:Destroy()
	else
		for _, obj in pairs(parent:GetDescendants()) do
			if obj:IsA('BasePart') then
				obj.Anchored = true
			end
		end
	end
end

return Ragdoll