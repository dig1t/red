local CollectionService = game:GetService("CollectionService")

local dLib = require(script.Parent)
local Util = dLib.import("Util")

local lib, methods = {}, {}
methods.__index = methods

function methods:getAll()
	return self.objects
end

function methods:destroy()
	self.objects = {}
	self.watching = nil
	
	if self.addWatcher then
		self.addWatcher:Disconnect()
		self.addWatcher = nil
	end
	
	if self.removeWatcher then
		self.removeWatcher:Disconnect()
		self.removeWatcher = nil
	end
end

function lib.watch(tagId)
	assert(tagId, 'CollectionService.watch - Missing tag id')
	
	local self = setmetatable({}, methods)
	
	self.objects = CollectionService:GetTagged(tagId) or {}
	self.watching = true
	
	self.addWatcher = CollectionService:GetInstanceAddedSignal(tagId):Connect(function(obj)
		self.objects[#self.objects + 1] = obj
	end)
	
	self.removeWatcher = CollectionService:GetInstanceRemovedSignal(tagId):Connect(function(obj)
		local index = table.find(self.objects, obj)
		
		if index and self.objects[index] then
			Util.tableRemove(self.objects, index)
		end
	end)
	
	return self
end

return lib