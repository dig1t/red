--- @class Server

--!strict

local Service = require(script.Parent.Service)
local Types = require(script.Parent.Types)
local redUtil = require(script.Parent.redUtil)

local remotes = redUtil.getRemotes()

local ignoredReducerKeys = {
	"init",
	"_redService",
	"name",
	"private",
}

local Server = {}
Server.__index = Server

export type ServerType = typeof(setmetatable(
	{} :: {
		_reducers: {
			[string]: (player: Player, payload: Types.ActionPayload?) -> any,
		},
		_privateReducers: {
			[string]: (player: Player, payload: Types.ActionPayload?) -> any,
		},
		_services: {
			[string]: any,
		},
		started: boolean,
	},
	Server
))

--[=[
	Creates a new server instance
	
	@return ServerType
]=]
function Server.new(): ServerType
	local self = setmetatable({}, Server) :: ServerType

	self._reducers = {}
	self._privateReducers = {}
	self._services = {}

	return self
end

--[=[
	Use this method to bind a service action to the server.
	
	Example:
	```luau
	server:bind("ACTION_TYPE", function(player: Player, payload: Types.ActionPayload?)
		-- Do something
	end)
	```
	
	@within Server
	@method bind
	@param actionType string
	@param reducer () -> any
	@param private boolean?
]=]
function Server.bind(self: ServerType, actionType: string, reducer: () -> any, private: boolean?)
	assert(typeof(actionType) == "string", "Action type must be a string")
	assert(typeof(reducer) == "function", "Action must be a function")

	self[private == true and "_privateReducers" or "_reducers"][actionType] = reducer
end

--[=[
	Use this method to unbind a service action from the server.
	
	Example:
	```luau
	server:unbind("ACTION_TYPE")
	```
	
	@within Server
	@method unbind
	@param id string
]=]
function Server.unbind(self: ServerType, id: string)
	assert(self._reducers[id] or self._privateReducers[id], "Action reducer does not exist")

	self._reducers[id] = nil
	self._privateReducers[id] = nil
end

--[=[
	Use this method to load a service into the server.
	
	Example:
	```luau
	server:loadService(game.ServerScriptService.Server.Services.MyService)
	```
	
	@within Server
	@method loadService
	@param moduleInstance ModuleScript
]=]
function Server.loadService(self: ServerType, moduleInstance: ModuleScript)
	assert(typeof(moduleInstance) == "Instance" and moduleInstance:IsA("ModuleScript"), "Path is not a ModuleScript")

	local service = require(moduleInstance) :: any

	assert(service.name, "Service does not have a name")
	assert(service._redService, "Service is not a red service")

	self._services[service.name] = service

	-- Iterate through service and format action names
	-- to include the controller name
	-- and capitalize all characters
	for reducerKey, reducerFn in pairs(service) do
		if
			table.find(ignoredReducerKeys, reducerKey)
			or typeof(reducerFn) ~= "function"
			or typeof(reducerKey) ~= "string"
		then
			continue
		end

		local actionType: string = string.upper(service.name) .. "_" .. string.upper(reducerKey)

		self:bind(
			actionType,
			reducerFn,
			typeof(service.private) == "table" and table.find(service.private, actionType) ~= nil -- Check if reducer is private
				or service.private == true -- Check if all reducers are private
		)
	end
end

--[=[
	Use this method to load multiple service modules into the server.
	
	Example:
	```luau
	server:loadServices(game.ServerScriptService.Server.Services:GetChildren())
	```
	
	@within Server
	@method loadServices
	@param services { ModuleScript }
]=]
function Server.loadServices(self: ServerType, services: { ModuleScript })
	for _, service: ModuleScript in pairs(services) do
		self:loadService(service)
	end
end

-- @desc Function for interal use only

--[=[
	Function for interal use only
	
	Arguments will be interpreted as either (actionType, payload) or (actionType, player, payload) depending on the number of arguments.
	
	Example:
	```luau
	server:localCall("ACTION_TYPE", player, payload)
	```
	
	@within Server
	@method localCall
	@param actionType string
	@param ... any
	@return any
]=]
function Server.localCall(self: ServerType, actionType: string, ...): any
	assert(typeof(actionType) == "string", "Action type must be a string")
	assert(
		self._reducers[actionType] or self._privateReducers[actionType],
		"Action \"" .. actionType .. "\" does not exist"
	)

	local serviceName: string = string.lower(string.split(actionType, "_")[1])
	local service: Service.ServiceType = self._services[serviceName]

	local success: boolean, res: Types.Action =
		pcall(self._reducers[actionType] or self._privateReducers[actionType], service, ...)

	if not success then
		error(res, 2)
	end

	if typeof(res) == "table" and not res.err then
		res.success = true
	end

	return res
end

--[=[
	Use this method to call an action.
	
	Example:
	```luau
	server:_call(action, player)
	```
	
	@within Server
	@method _call
	@param action Types.Action
	@param player Player?
	@return Types.Action?
]=]
function Server._call(self: ServerType, action: Types.Action, player: Player?): Types.Action?
	assert(action and typeof(action.type) == "string", "Action type must be a string")

	if not (self._reducers[action.type] or self._privateReducers[action.type]) then
		return
	elseif player and self._privateReducers[action.type] then
		-- Player should not be calling a private action

		return -- error(player.userId .. " attempted to call a private action")
	end

	local args = {}

	local usingPlayerArgument: boolean? = typeof(player) == "Instance" and player:IsA("Player")
	local usingActionPlayer: boolean? = typeof(action.player) == "Instance" and action.player:IsA("Player")

	local targetPlayer: Player? = (usingPlayerArgument and player) or (usingActionPlayer and action.player) or nil

	table.insert(args, targetPlayer) -- Check to make sure the player argument is a valid player

	if action.payload and typeof(action.payload) == "table" then
		args[#args + 1] = action.payload :: any
	end

	local serviceName: string = string.lower(string.split(action.type, "_")[1])
	local service: Service.ServiceType = self._services[serviceName]

	service.name = serviceName

	local success: boolean, res: Types.Action | string = pcall(
		self._reducers[action.type] or self._privateReducers[action.type],
		service,
		args[1], -- TODO: ??
		args[2] -- TODO: ??
	)

	if not success then
		task.spawn(function()
			local _player = targetPlayer and targetPlayer:IsA("Player") and targetPlayer or nil
			local userId: number = _player and _player.UserId or 0

			if typeof(res) == "string" then
				error(res .. (userId and ` - UserId: {userId}` or ""), 2)
			end
		end)

		return {
			type = action.type,
			err = typeof(res) == "string" and res or nil,
			success = false,
		} :: Types.Action
	end

	-- Add a success property to the action
	if typeof(res) == "table" and not res.err and res.success == nil then
		res.success = true
	elseif not res then
		res = {
			type = action.type,
			success = true,
		}
	end

	return res :: Types.Action
end

--[=[
	Initializes the server.
	
	This will call the ```init``` method on all services.
	
	@within Server
	@method init
]=]
function Server.init(self: ServerType)
	for _, service in pairs(self._services) do
		if not service.init then
			continue
		end

		assert(typeof(service.init) == "function", "Expected service.init to be a function")

		task.spawn(function()
			debug.setmemorycategory(service.name)
			service:init()
		end)
	end

	-- Hook listeners

	-- store:dispatch() called from client
	remotes.Client.OnServerEvent:Connect(function(player: Player, action: Types.Action)
		if action.method and action.method == "get_result" then
			return
		end

		action.player = player

		local res: Types.Action? = self:_call(action, player)

		if not res then
			return
		end

		-- If the action's method is "get" fire it back
		-- to the sender
		if action.method and action.method == "get" then
			assert(typeof(res) == "table", action.type .. " - Cannot return a " .. typeof(res) .. " type to a client.")

			res.uid = action.uid

			-- Change method to get result since
			-- the server is now firing the result
			-- to the client.
			res.method = "get_result"

			remotes.Client:FireClient(player, res)
		end
	end)

	-- store:dispatch() called from server
	remotes.Server.Event:Connect(function(action: Types.Action)
		if action.method and action.method == "get_result" then
			-- Ignore actions with get_result methods, these will
			-- always be routed back into this listener
			-- after calling remotes.Server:Fire()
			return
		end

		local res = self:_call(action)

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
