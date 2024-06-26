--[=[
	@class Store
]=]

--!strict

local RunService = game:GetService("RunService")

local Constants = require(script.Parent.Constants)
local Promise = require(script.Parent.Parent.Promise)
local Types = require(script.Parent.Types)
local Util = require(script.Parent.Parent.Util)
local redUtil = require(script.Parent.redUtil)

local remotes = redUtil.getRemotes()
local isServer: boolean = RunService:IsServer()

local Store = {}
Store.__index = Store

export type StoreType = typeof(setmetatable(
	{} :: {
		_connections: { [number]: RBXScriptConnection },
		_subscribers: { [Types.SubscriptionId]: (action: Types.Action) -> nil },
	},
	Store
))

--[=[
	Creates a new store instance
	
	@return StoreType
]=]
function Store.new(): StoreType
	local self = setmetatable({}, Store) :: StoreType

	self._connections = {}
	self._subscribers = {}

	return self
end

--[=[
	Dispatches an action
	
	The first argument can be a player or a table of players, which will determine who receives the action event.
	
	If the first argument is ```true```, then the action will be fired to ***all clients***.
	
	The second argument is the action object. (Types.Action)
	
	@within Store
	@method dispatch
	@param target Player | { Player } | true
	@param action Types.Action
]=]
function Store.dispatch(_self: StoreType, ...: any)
	local args = { ... }

	local action: Types.Action = #args == 1 and args[1] or args[2]

	assert(action ~= nil, "Dispatch requires an action")
	assert(typeof(action) == "table", "Action must be a table")
	assert(action.type, "Action must have an action type")

	local recipient: Player | { Player } = #args == 2
		and (typeof(args[1]) == "Instance" or typeof(args[1]) == "table")
		and args[1]
	local fireToAll: boolean = #args == 2 and typeof(args[1]) == "boolean" and args[1]

	if isServer then
		action.success = not action.err

		if not action.success and not action.err and action.type then
			action.err = action.type .. " - Error occured"
		end
	end

	-- If no recipient is specified, then
	-- the action will fire to the server
	-- From either the client (client-to-server) or the server (server-to-server)
	if #args == 1 then
		if isServer then
			remotes.Server:Fire(action)
		else
			remotes.Client:FireServer(action)
		end

	-- If a recipient is specified, then
	-- the action will fire to the client(s)
	-- from the server. If the recipient is
	-- a table, then the action will fire
	elseif #args == 2 then
		assert(isServer, "Dispatcher must be the server")

		if recipient and not fireToAll then
			if typeof(recipient) == "Instance" and recipient:IsA("Player") then
				remotes.Client:FireClient(recipient, action)
			elseif typeof(recipient) == "table" then
				for _, player in pairs(recipient) do
					remotes.Client:FireClient(player, action)
				end
			end
		elseif fireToAll then
			remotes.Client:FireAllClients(action)
		else
			warn(`Store - could not dispatch action: {action.type}`) -- Convert to error handler (?)
		end
	end
end

--[=[
	Dispatches an action with a unique id, then yields and watches for incoming actions with the same tag, and returns the action as a result
	@within Store
	@method get
	@param self StoreType
	@param action Types.Action
	@return Types.Action?
]=]
function Store.get(self: StoreType, action: Types.Action): Types.Action?
	assert(typeof(action) == "table", "Action must be a table")
	assert(action.type, "Action must have an action type")

	local uid = Util.randomString(8)

	action.uid = uid
	action.method = "get"

	local connections: { RBXScriptConnection } = {}
	local res: Types.Action?
	local responseReceived: boolean?

	local promise = Promise.new(function(resolve, _reject)
		if isServer then
			connections[#connections + 1] = remotes.Client.OnServerEvent:Connect(
				function(player: Player, _action: Types.Action)
					-- From client
					_action.player = player

					if _action.method == "get_result" and _action.uid == uid then
						resolve(_action)
					end
				end
			)
			connections[#connections + 1] = remotes.Server.Event:Connect(function(_action: Types.Action)
				-- From server
				if _action.method == "get_result" and _action.uid == uid then
					resolve(_action)
				end
			end)
		else
			connections[#connections + 1] = remotes.Client.OnClientEvent:Connect(function(_action: Types.Action)
				-- From server
				if _action.method == "get_result" and _action.uid == uid then
					resolve(_action)
				end
			end)
		end

		self:dispatch(action)
	end)
		:andThen(function(_action)
			res = _action
			responseReceived = true
		end)
		:catch(function(err: string)
			res = {
				err = err,
			} :: Types.Action
		end)
		:finally(function()
			for _, connection: RBXScriptConnection in pairs(connections) do
				connection:Disconnect() -- Disconnect the watchers
			end
		end)

	local start: number = os.clock()
	local timeout: number = action.timeout or Constants.STORE_TIMEOUT

	repeat
		RunService.Stepped:Wait()
	until res ~= nil or responseReceived or os.clock() - start >= timeout

	if not responseReceived then
		promise:_reject(`Timed out while waiting for action: "{action.type}"`)
	end

	return res
end

function Store._callSubscribers(self: StoreType, action: Types.Action, safeCall: boolean?)
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

--[=[
	Sets up a subscription to listen for actions dispatched by the store
	
	When an action is dispatched, the callback function will be called with the action as an argument
	
	@within Store
	@method subscribe
	@param callback (action: Types.Action) -> ()
	@return Types.SubscriptionId
]=]
function Store.subscribe(self: StoreType, callback: (action: Types.Action) -> ()): Types.SubscriptionId
	assert(typeof(callback) == "function", "Callback argument must exist and be a function")

	local subscriptionId: Types.SubscriptionId = Util.randomString(8) -- Unique reference ID used for unsubscribing

	if Util.tableLength(self._subscribers) == 0 then
		-- Hook connections to start receiving events

		if isServer then
			-- From client
			self._connections[#self._connections + 1] = remotes.Client.OnServerEvent:Connect(
				function(player: Player, action: Types.Action)
					action.player = player

					self:_callSubscribers(action, true)
				end
			)

			-- From server
			self._connections[#self._connections + 1] = remotes.Server.Event:Connect(function(action: Types.Action)
				self:_callSubscribers(action, true)
			end)
		else
			-- From client
			self._connections[#self._connections + 1] = remotes.Client.OnClientEvent:Connect(
				function(action: Types.Action)
					self:_callSubscribers(action, false)
				end
			)
		end
	end

	self._subscribers[subscriptionId] = callback

	return subscriptionId
end

--[=[
	Unsubscribes a listener from the store using the subscription id returned from ```Store:subscribe()```.
	
	@within Store
	@method unsubscribe
	@param id Types.SubscriptionId
]=]
function Store.unsubscribe(self: StoreType, id: Types.SubscriptionId)
	assert(self._subscribers[id], "Store:unsubscribe() - Event listener id does not exist")

	self._subscribers[id] = nil

	if Util.tableLength(self._subscribers) == 0 then
		-- Disconnect all connections to prevent
		-- unneeded events from being received

		for index: number, connection: RBXScriptConnection in pairs(self._connections) do
			connection:Disconnect()
			self._connections[index] = nil
		end
	end
end

return Store
