local Maid, methods = {}, {}
methods.__index = methods

function methods:addTask(task)
	
end

function methods:clean()
	for id, task in pairs(self._tasks) do
		if typeof(task) == 'function' then
			task()
		elseif typeof(task) == 'RBXScriptConnection' then
			task:Disconnect()
		elseif task.Destroy then
			task:Destroy()
		elseif task.destroy then -- UIKit object
			task:destroy()
		end
		
		self.tasks[id] = nil
	end
end

function Maid.new()
	local self = setmetatable({}, methods)
	
	self._tasks = {}
	
	return self
end

return Maid