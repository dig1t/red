-- src/ReplicatedStorage/red/Modules/Server.lua

local red = script.Parent.Parent

local Server = {}
local methods = {}

function Server.new()
	local self = {}
	
	self._actions = {}
	self.modules = {}
	
	return setmetatable(methods, {
		__index = self
	})
end

function methods.error(err)
	error(err, 3)
end

function methods:bind(type, fn)
	if (
		assert(typeof(type) == 'string', 'Action type must be a string') and
		assert(typeof(fn) == 'function', 'Action must be a function')
	) then
		self._actions[type] = fn
	end
end

function methods:unbind(id)
	if assert(self.actions[id], 'Action does not exist') then
		self._actions[id] = nil
	end
end

function methods:loadModule(path)
	if (
		assert(path:IsA('ModuleScript'), 'Module must be a ModuleScript')
	) then
		local module = require(path)
		
		if assert(module.name, 'Module must have a name') then
			self.modules[module.name] = module.version or true
			
			-- Iterate through module and format action names
			-- to include the controller name
			-- and capitalize all characters
			
			for name, func in pairs(module) do
				if typeof(func) == 'function' then
					self:bind(string.upper(module.name) .. '_' .. string.upper(name), func)
				end
			end
		end
	end
end

function methods:loadModules(modules)
	for k, module in pairs(modules) do
		self:loadModule(module)
	end
end

-- Use inside the server for local calls only
-- Arguments will be interpreted as either (actionType, payload) or (actionType, player, payload)
function methods:localCall(actionType, ...)
	if (
		actionType and
		assert(typeof(actionType) == 'string', 'Action type must be a string') and
		assert(self._actions[actionType], 'Action does not exist')
	) then
		local success, res = pcall(self._actions[actionType], ...)
		
		if not success then
			self.error(res)
		end
		
		return res
	end
end

function methods:call(action, player)
	if (
		action and
		assert(typeof(action.type) == 'string', 'Action type must be a string') and
		assert(self._actions[action.type], 'Action does not exist')
	) then
		local args = {}
		table.insert(
			args,
			(player and player:IsA('Player') and player) or
			(action.player and action.player:IsA('Player') and action.player)
		) -- Check to make sure the player argument is a valid player
		if action.payload then table.insert(args, action.payload) end
		
		local success, res = pcall(self._actions[action.type], args[1] and args[1], args[2] and args[2])
		
		if not success then
			self.error(res, type(args[1]) == 'userdata' and args[1]:IsA('Player') and args[1].userId)
		end
		
		return res
	end
end

function methods:init()
	-- Hook listeners
	
	-- store:get() called from a client
	function red.Remotes.ClientCall.OnServerInvoke(player, action)
		return self:call(action, player)
	end
	
	-- store:get() called from the server
	function red.Remotes.ServerCall.OnInvoke(action)
		return self:call(action)
	end
	
	-- store:dispatch() called from a client
	red.Remotes.Client.OnServerEvent:Connect(function(player, action)
		action.player = player
		
		if action.callback then
			red.Remotes.Client:FireClient(player, self:call(action, player))
		else
			self:call(action, player)
		end
	end)
	
	-- store:dispatch() called from the server
	red.Remotes.Server.Event:Connect(function(action)
		self:call(action)
	end)
end

return Server