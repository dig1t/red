local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local dLib = require(script.Parent.dLib)
local Util = dLib.import("Util")
local Promise = dLib.import("Promise")

local Constants = require(script.Parent.Constants)

local remotes = ReplicatedStorage[Constants.REMOTE_FOLDER_NAME]
local isServer = RunService:IsServer()

local Store = {}
Store.__index = Store

--[[
	@desc dispatches an action
	@param player|boolean arg[1] - determines who receives the action event (optional)
	@param object action arg[1]|arg[2] - action
]]--
function Store:dispatch(...): nil
	local args = {...}
	
	local action = #args == 1 and args[1] or args[2]
	
	assert(typeof(action) == "table", "Action must be a table")
	assert(action.type, "Action must have an action type")
	
	local recipient = #args == 2 and (typeof(args[1]) == "Instance" or typeof(args[1]) == "table") and args[1]
	local fireToAll = #args == 2 and typeof(args[1]) == "boolean" and args[1]
	
	if isServer then
		action.success = not action.err
		
		if not action.success and not action.err and action.type then
			action.err = action.type .. " - Error occured"
		end
	end
	
	--[[if not action.method then
		action.method = "post"
	end]]
	
	if #args == 1 then
		if isServer then
			remotes.Server:Fire(action)
		else
			remotes.Client:FireServer(action)
		end
	elseif #args == 2 then
		assert(isServer, "Dispatcher must be the server")
		
		if recipient and not fireToAll then
			if typeof(recipient) == "Instance" then
				remotes.Client:FireClient(recipient, action)
			elseif typeof(recipient) == "table" then
				for _, player in pairs(recipient) do
					remotes.Client:FireClient(player, action)
				end
			end
		elseif fireToAll then
			remotes.Client:FireAllClients(action)
		elseif self.error then
			warn("Store - could not dispatch action" .. action.type) -- Convert to error handler (?)
		end
	end
end

type Action = {
	uid: string?,
	method: string?,
	player: Player?
}

type SubscriptionId = string

--[[
	@desc dispatches an action with a unique id,
		then yields and watches for incoming actions
		with the same tag and returns the action as a result
	@return result
]]--
function Store:get(action: Action): any
	assert(typeof(action) == "table", "Action must be a table")
	assert(action.type, "Action must have an action type")
	
	local uid = Util.randomString(8)
	
	action.uid = uid
	action.method = "get"
	
	local connections = {}
	local res
	local responseReceived
	
	local promise = Promise.new(function(resolve, reject)
		connections[#connections + 1] = isServer and remotes.Client.OnServerEvent:Connect(function(player, _action)
			-- From client
			_action.player = player
			
			if _action.method == "get_result" and _action.uid == uid then
				resolve(_action)
			end
		end) or remotes.Client.OnClientEvent:Connect(function(_action)
			-- From server
			if _action.method == "get_result" and _action.uid == uid then
				resolve(_action)
			end
		end)
		
		if isServer then
			connections[#connections + 1] = remotes.Server.Event:Connect(function(_action)
				-- From server
				if _action.method == "get_result" and _action.uid == uid then
					resolve(_action)
				end
			end)
		end
		
		self:dispatch(action)
	end):thenDo(function(_action)
		res = _action
		responseReceived = true
	end):catch(function(err)
		res = {
			err = err
		}
	end):finally(function()
		for _, connection in pairs(connections) do
			connection:Disconnect() -- Disconnect the watcher
		end
	end)
	
	local start = os.clock()
	local timeout = action.timeout or 5
	
	repeat
		RunService.Stepped:Wait()
	until res ~= nil or responseReceived or os.clock() - start >= timeout
	
	if not responseReceived then
		promise:reject('Timed out while waiting for action: "" .. action.type .. ""')
	end
	
	return res
end

function Store:_callSubscribers(action, safeCall)
	if not action.type or action.method == "get" or action.method == "get_result" then
		-- Ignore get method actions, these
		-- will be processed by store:get()
		return
	end
	
	for _, callback in pairs(self._subscribers) do
		if safeCall then
			pcall(callback, action)
		else
			callback(action)
		end
	end
end

function Store:subscribe(fn: () -> nil): SubscriptionId
	assert(typeof(fn) == "function", "Callback argument must exist and be a function")
	
	local id: SubscriptionId = Util.randomString(8) -- Unique reference ID used for unsubscribing
	
	if Util.tableLength(self._subscribers) == 0 then
		-- Hook connections to start receiving events
		
		if isServer then
			-- From client
			self._connections[#self._connections + 1] = remotes.Client.OnServerEvent:Connect(
				function(player: Player, action: Action)
					action.player = player
					
					self:_callSubscribers(action, true)
				end
			)
			
			-- From server
			self._connections[#self._connections + 1] = remotes.Server.Event:Connect(
				function(action: Action)
					self:_callSubscribers(action, true)
				end
			)
		else
			-- From client
			self._connections[#self._connections + 1] = remotes.Client.OnClientEvent:Connect(
				function(action: Action)
					self:_callSubscribers(action)
				end
			)
		end
	end
	
	self._subscribers[id] = fn
	
	return id
end

function Store:unsubscribe(id: SubscriptionId): nil
	assert(self._subscribers[id], 'Store:unsubscribe() - Event listener id does not exist')
	
	self._subscribers[id] = nil
	
	if Util.tableLength(self._subscribers) == 0 then
		-- Disconnect all connections to prevent
		-- unneeded events from being received
		
		for i, connection in pairs(self._connections) do
			connection:Disconnect()
			self._connections[i] = nil
		end
	end
end

function Store.new()
	local self = setmetatable({}, Store)
	
	self._connections = {}
	self._subscribers = {}
	self.modules = {}
	
	return self
end

return Store