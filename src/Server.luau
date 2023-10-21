--!strict

local redTypes = require(script.Parent.redTypes)
local redUtil = require(script.Parent.redUtil)

local remotes = redUtil.getRemotes()

local Server = {}
Server.__index = Server

function Server.new()
	local self = setmetatable({}, Server)
	
	self._reducers = {}
	self._privateReducers = {}
	self._services = {}
	
	math.randomseed(os.clock() * 1e6)
	
	return self
end

function Server:bind(actionType: string, reducer: () -> any, private: boolean?)
	assert(typeof(actionType) == "string", "Action type must be a string")
	assert(typeof(reducer) == "function", "Action must be a function")
	
	self[private == true and "_privateReducers" or "_reducers"][actionType] = reducer
end

function Server:unbind(id)
	assert(self._reducers[id] or self._privateReducers[id], "Action reducer does not exist")
	
	self._reducers[id] = nil
	self._privateReducers[id] = nil
end

function Server:loadService(moduleInstance: ModuleScript)
	assert(
		typeof(moduleInstance) == "Instance" and moduleInstance:IsA("ModuleScript"),
		"Path is not a ModuleScript"
	)
	
	local service: redTypes.ServerService = require(moduleInstance)
	
	assert(service.name, "Service does not have a name")
	assert(service._redService, "Service is not a red service")
	
	self._services[service.name] = service
	
	-- Iterate through service and format action names
	-- to include the controller name
	-- and capitalize all characters
	for key, reducer in pairs(service) do
		if typeof(reducer) == "function" and typeof(key) == "string" then
			local actionType: string = string.upper(service.name) .. "_" .. string.upper(key)
			
			self:bind(
				actionType,
				reducer,
				typeof(service.private) == "table" and
					table.find(service.private, actionType) ~= nil or -- Check if reducer is private
					service.private == true -- Check if all reducers are private
			)
		end
	end
end

function Server:loadServices(services: { ModuleScript })
	for _, service: ModuleScript in pairs(services) do
		self:loadService(service)
	end
end

-- @desc Function for interal use only
-- Arguments will be interpreted as either (actionType, payload) or (actionType, player, payload)
function Server:localCall(actionType, ...)
	assert(typeof(actionType) == "string", "Action type must be a string")
	assert(
		self._reducers[actionType] or self._privateReducers[actionType],
		"Action \"" .. actionType .. "\" does not exist"
	)
	
	local serviceName: string = string.lower(string.split(actionType, "_")[1])
	local service: redTypes.ServerService = self._services[serviceName]
	
	local success: boolean, res: redTypes.Action = pcall(
		self._reducers[actionType] or self._privateReducers[actionType], service, ...
	)
	
	if not success then
		error(res, 2)
	end
	
	if typeof(res) == "table" and not res.err then
		res.success = true
	end
	
	return res
end

function Server:call(action, player)
	assert(action and typeof(action.type) == "string", "Action type must be a string")
	
	if not (self._reducers[action.type] or self._privateReducers[action.type]) then
		return
	elseif player and self._privateReducers[action.type] then
		-- Player should not be calling a private action
		
		return -- error(player.userId .. " attempted to call a private action")
	end
	
	local args = {}
	
	table.insert(
		args,
		(player and player:IsA("Player") and player) or
		(action.player and action.player:IsA("Player") and action.player)
	) -- Check to make sure the player argument is a valid player
	
	if action.payload and typeof(action.payload) == "table" then
		table.insert(args, action.payload)
	end
	
	local serviceName: string = string.lower(string.split(action.type, "_")[1])
	local service: redTypes.ServerService = self._services[serviceName]
	
	local success: boolean, res: redTypes.Action | string = pcall(
		self._reducers[action.type] or self._privateReducers[action.type],
		service,
		args[1], --// TODO: ??
		args[2] --// TODO: ??
	)
	
	if not success then
		task.spawn(function()
			error(
				res .. (
					typeof(args[1]) == "Instance" and args[1]:IsA("Player") and (" - UserId: " .. args[1].UserId) or ""
				),
				2
			)
		end)
		
		res = {
			type = action.type,
			err = res,
			success = false
		} :: redTypes.Action
	end
	
	-- Add a success property to the action
	if typeof(res) == "table" and not res.err and res.success == nil then
		res.success = true
	elseif not res then
		res = {
			success = true
		}
	end
	
	return res
end

function Server:init()
	for _, service in pairs(self._services) do
		if typeof(service.init) == "function" then
			service:init()
		end
	end
	
	-- Hook listeners
	
	-- store:dispatch() called from client
	remotes.Client.OnServerEvent:Connect(function(player: Player, action: redTypes.Action)
		if action.method and action.method == "get_result" then
			return
		end
		
		action.player = player
		
		local res: redTypes.Action = self:call(action, player)
		
		if not res then
			return
		end
		
		-- If the action's method is "get" fire it back
		-- to the sender
		if action.method and action.method == "get" then
			assert(
				typeof(res) == "table",
				action.type .. " - Cannot return a " .. typeof(res) .. " type to a client."
			)
			
			res.uid = action.uid
			
			-- Change method to get result since
			-- the server is now firing the result
			-- to the client.
			res.method = "get_result"
			
			remotes.Client:FireClient(player, res)
		end
	end)
	
	-- store:dispatch() called from server
	remotes.Server.Event:Connect(function(action: redTypes.Action)
		if action.method and action.method == "get_result" then
			-- Ignore actions with get_result methods, these will
			-- always be routed back into this listener
			-- after calling remotes.Server:Fire()
			return
		end
		
		local res = self:call(action)
		
		if not res then
			return
		end
		
		-- If the action's method is "get" fire it back
		-- to the sender
		if action.method and action.method == "get" then
			assert(
				typeof(res) == "table",
				action.type .. " - Cannot return a " .. typeof(res) .. " type to a client. Only tables can be returned."
			)
			
			res.uid = action.uid
			
			-- Change method to get result since
			-- the server is now firing the result
			-- to the client.
			res.method = "get_result"
			
			remotes.Server:Fire(res)
		end
	end)
	
	self.started = true
end

return Server
