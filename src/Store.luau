--[=[
	@class Store

	#### Setup
	```lua
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local red = require(ReplicatedStorage.Packages.red)

	local store: red.StoreType = red.Store.new() -- Constructs a new store
	```
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

local _middleware: { (action: Types.Action) -> () } = {}

export type StoreType = typeof(setmetatable(
	{} :: {
		_connections: { [number]: RBXScriptConnection },
		_subscribers: { [Types.SubscriptionId]: (action: Types.Action) -> nil },
	},
	Store
))

--[=[
	Applies middleware to the store

	The middleware function will be called before the action is dispatched.

	```lua
	store:use(function(action: red.Action)
		if action.type == "HELLO_WORLD" then
			action.payload.message = action.payload.message .. "!"
		end
	end)

	store:dispatch({
		type = "HELLO_WORLD",
		payload = {
			message = "Hello World"
		}
	})

	-- Payload after middleware: "Hello World!"
	```

	@within Store
	@method use
	@param middleware (action: Types.Action) -> ()
]=]
function Store.use(middleware: (action: Types.Action) -> ())
	_middleware[#_middleware + 1] = middleware
end

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

	```lua
	local Players = game:GetService("Players")

	-- Dispatch to the server
	store:dispatch({
		type = "PLAYER_KILL",
		player = Players.Player1 -- The first argument in the binded action.
	})

	store:dispatch({
		type = "PLAYER_DAMAGE",
		player = { Players.Player2, Players.Player3 }
		payload = { -- The second argument in the binded action.
			damage = 50
		}
	})

	store:dispatch({ -- Called from the server
		type = "GAME_STOP",
		payload = { -- This would be the first argument since there is no reason to include a player parameter.
			message = "Game over"
		}
	})

	-- Dispatch to all clients
	store:dispatch(true, {
		type = "UI_NOTIFICATION",
		payload = {
			text = "Hello World!"
		}
	})

	-- Dispatch to one client
	store:dispatch(Players.Player1, {
		type = "UI_SPECTATE_START"
	})

	-- Dispatch to multiple clients
	store:dispatch({ Players.Player2, Players.Player3 }, {
		type = "UI_GAME_TIMER",
		payload = {
			duration = 60 -- Show a countdown timer lasting 60 seconds
		}
	})
	```

	@within Store
	@method dispatch
	@param target Player | { Player } | true
	@param action Types.Action
]=]
function Store.dispatch(_self: StoreType, ...: { any })
	local args: { any } = { ... }

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

	-- Handle middleware
	for _, middleware: (action: Types.Action) -> () in _middleware do
		local success, err: any = pcall(middleware, action)

		if not success then
			warn("Middleware error: " .. (tostring(err) or "Unknown error"))
		end
	end

	if #args == 1 then
		-- If no recipient is specified, then
		-- the action will fire to the server
		-- From either the client (client-to-server) or the server (server-to-server)

		if isServer then
			remotes.Server:Fire(action)
		else
			remotes.Client:FireServer(action)
		end
	elseif #args == 2 then
		-- If a recipient is specified, then
		-- the action will fire to the client(s)
		-- from the server. If the recipient is
		-- a table, then the action will fire

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
	Dispatches an action and yields until an action is returned with a result.
	If the action is not returned within the timeout, the get request will fail.

	```lua
	-- Client
	local fetch = store:get({ -- Fetch player stats from the server
		type = "PLAYER_STATS",
	})
	local stats = fetch.success and fetch.payload.stats

	if stats then -- Successfull stats fetch
		print(stats)
	end

	-- Server
	local fetch = store:get({ -- Fetch player stats from the server
		type = "PLAYER_STATS",
		player = Players.Player1 -- If action is for a player, this parameter must be defined
	})
	local stats = fetch.success and fetch.payload.stats

	if stats then -- Successfull stats fetch
		print(stats)
	else
		warn(fetch.err)
	end
	```

	@within Store
	@method get
	@param self StoreType
	@param action Types.Action
	@return Types.Action
]=]
function Store.get(self: StoreType, action: Types.Action): Types.Action
	assert(typeof(action) == "table", "Action must be a table")
	assert(action.type, "Action must have an action type")

	local uid: string = Util.randomString(8)

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
			connections[#connections + 1] = remotes.Server.Event:Connect(
				function(_action: Types.Action)
					-- From server
					if _action.method == "get_result" and _action.uid == uid then
						resolve(_action)
					end
				end
			)
		else
			connections[#connections + 1] = remotes.Client.OnClientEvent:Connect(
				function(_action: Types.Action)
					-- From server
					if _action.method == "get_result" and _action.uid == uid then
						resolve(_action)
					end
				end
			)
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
		or {
			err = "Action failed to return a result. Timeout exceeded",
		} :: Types.Action
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
function Store.subscribe(
	self: StoreType,
	callback: (action: Types.Action) -> ()
): Types.SubscriptionId
	assert(
		typeof(callback) == "function",
		"Callback argument must exist and be a function"
	)

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
			self._connections[#self._connections + 1] = remotes.Server.Event:Connect(
				function(action: Types.Action)
					self:_callSubscribers(action, true)
				end
			)
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

	```lua
	-- Setup the listener
	local connectionId

	connectionId = store:subscribe(function(action: red.Action)
		if action.type == "HELLO_WORLD" then
			print(action.type)
			store:unsubscribe(connectionId) -- Stop receiving actions
		end
	end)

	task.wait(2)

	store:unsubscribe(connectionId) -- Stop receiving actions
	```

	@within Store
	@method unsubscribe
	@param id Types.SubscriptionId
]=]
function Store.unsubscribe(self: StoreType, id: Types.SubscriptionId)
	assert(
		self._subscribers[id],
		"Store:unsubscribe() - Event listener id does not exist"
	)

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
