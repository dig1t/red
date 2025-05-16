--[=[
	@class Store

	Dispatcher for actions to be dispatched to the server or clients.

	#### Setup
	```lua
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local red = require(ReplicatedStorage.Packages.red)

	-- Client
	red.subscribe(function(action: red.Action)
		print(action.type)
	end)

	red.dispatch({
		type = "HELLO_WORLD",
		payload = {
			message = "Hello World"
		}
	})

	-- Server

	-- Dispatch to all clients
	red.dispatch(true, {
		type = "HELLO_WORLD",
		payload = {
			message = "Hello World"
		}
	})

	-- Dispatch to one client
	red.dispatch(Players.Player1, {
		type = "HELLO_WORLD",
		payload = {
			message = "Hello World"
		}
	})
	```
]=]

--!strict

local RunService = game:GetService("RunService")

local Constants = require(script.Parent.Constants)
local Promise = require(script.Parent.Parent.Promise)
local Signal = require(script.Parent.Parent.Signal)
local Types = require(script.Parent.Types)
local Util = require(script.Parent.Parent.Util)
local redUtil = require(script.Parent.redUtil)

local remotes: { Client: RemoteEvent } = redUtil.getRemotes()
local isServer: boolean = RunService:IsServer()

local Store = {}

local _middleware: { (action: Types.Action<any>) -> () } = {}

local _connections: { [number]: RBXScriptConnection } = {}
local signal: Signal.Signal<Types.Action<any>> = Signal.new()

function Store.bind(actionType: string, callback: Types.BindCallback)
	Store.subscribeTo(actionType, function(action: Types.Action<any>)
		local player: Player? = action.player

		if player then
			local res: Types.ActionPayload<any>? = callback(player, action.payload)

			-- Handle get requests
			if res and action.method == "get" then
				-- If the action is a get request, then
				-- return the result to the client
				action.method = "get_result"
				action.payload = res

				Store.dispatch(player, action)
			end
		end
	end)
end

--[=[
	Loads handlers that listen for actions dispatched by the store

	```lua
	-- Handlers/Player.luau

	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local red = require(ReplicatedStorage.Packages.red)

	return function(bind: red.Bind)
		bind("PLAYER_RESPAWN_REQUEST", function(player: Player)
			print(player.Name .. " is requesting a respawn")
		end)

		bind("PLAYER_TELEPORT", function(player: Player, payload: red.ActionPayload<CFrame>)
			-- Player is requesting to teleport to a location
			player.Character.PrimaryPart.CFrame = payload
		end)
	end
	```

	```lua
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local red = require(ReplicatedStorage.Packages.red)

	-- Server

	-- Require the handler
	red.useHandler(require(script.Parent.Handlers.Player))

	-- Give the location of a handler ModuleScript
	red.useHandler(script.Parent.Handlers.Player)
	```

	@within Store
	@method useHandler
	@param handler Handler | ModuleScript
]=]
function Store.useHandler(handler: Types.Handler | ModuleScript)
	local _handler: Types.Handler

	if typeof(handler) == "function" then
		_handler = handler
	elseif typeof(handler) == "Instance" and handler:IsA("ModuleScript") then
		_handler = require(handler) :: Types.Handler
	end

	if _handler then
		_handler(Store.bind)
	end
end

--[=[
	Shortcut for `useHandler()` that loads multiple handlers.

	Loads multiple handlers that listen for actions dispatched by the store

	Methods of use:
	```lua
	local Player = require(script.Parent.Handlers.Player)
	local Game = require(script.Parent.Handlers.Game)

	red.useHandlers({
		Player,
		Game
	})
	```

	```lua
	-- Load a folder of handlers
	red.useHandlers(script.Parent.Handlers)
	```

	@within Store
	@method useHandlers
	@param handlers { Handler | ModuleScript } | Instance
]=]
function Store.useHandlers(handlers: { Types.Handler | ModuleScript } | Instance)
	local _handlers: { Types.Handler | ModuleScript }

	if typeof(handlers) == "Instance" then
		_handlers = {}

		for _, handler: ModuleScript | Instance in pairs(handlers:GetChildren()) do
			if handler:IsA("ModuleScript") then
				table.insert(_handlers, handler)
			end
		end
	end

	for _, handler: Types.Handler | ModuleScript in pairs(_handlers) do
		Store.useHandler(handler)
	end
end

--[=[
	Applies middleware to the store

	The middleware function will be called before the action is dispatched.

	```lua
	store.use(function(action: red.Action)
		if action.type == "HELLO_WORLD" then
			action.payload.message = action.payload.message .. "!"
		end
	end)

	store.dispatch({
		type = "HELLO_WORLD",
		payload = {
			message = "Hello World"
		}
	})

	-- Payload after middleware: "Hello World!"
	```

	@within Store
	@method use
	@param middleware (action: Types.Action<any>) -> ()
]=]
function Store.use(middleware: (action: Types.Action<any>) -> ())
	_middleware[#_middleware + 1] = middleware
end

--[=[
	Dispatches an action

	The first argument can be a player or a table of players, which will determine who receives the action event.

	If the first argument is ```true```, then the action will be fired to ***all clients***.

	The second argument is the action object. (Types.Action)

	```lua
	local Players = game:GetService("Players")

	-- Dispatch to the server
	store.dispatch({
		type = "PLAYER_KILL",
		player = Players.Player1 -- The first argument in the binded action.
	})

	store.dispatch({
		type = "PLAYER_DAMAGE",
		player = { Players.Player2, Players.Player3 }
		payload = { -- The second argument in the binded action.
			damage = 50
		}
	})

	store.dispatch({ -- Called from the server
		type = "GAME_STOP",
		payload = { -- This would be the first argument since there is no reason to include a player parameter.
			message = "Game over"
		}
	})

	-- Dispatch to all clients
	store.dispatch(true, {
		type = "UI_NOTIFICATION",
		payload = {
			text = "Hello World!"
		}
	})

	-- Dispatch to one client
	store.dispatch(Players.Player1, {
		type = "UI_SPECTATE_START"
	})

	-- Dispatch to multiple clients
	store.dispatch({ Players.Player2, Players.Player3 }, {
		type = "UI_GAME_TIMER",
		payload = {
			duration = 60 -- Show a countdown timer lasting 60 seconds
		}
	})
	```

	@within Store
	@method dispatch
	@param target Player | { Player } | true
	@param action Types.Action<any>
]=]
function Store.dispatch(...: any)
	local args: { any } = { ... }

	local action: Types.Action<any> = #args == 1 and args[1] or args[2]

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
	for _, middleware: (action: Types.Action<any>) -> () in _middleware do
		local success, err: any = pcall(middleware, action)

		if not success then
			warn("Middleware error: " .. (tostring(err) or "Unknown error"))
		end
	end

	if #args == 1 then
		-- If no recipient is specified, then
		-- the action will fire to the server
		-- From either the client (client-to-server) or the server (server-to-server)

		if not isServer then
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
	local fetch = store.get({ -- Fetch player stats from the server
		type = "PLAYER_STATS",
	})
	local stats = fetch.success and fetch.payload.stats

	if stats then -- Successfull stats fetch
		print(stats)
	end
	```

	@within Store
	@method get
	@param action Types.Action<any>
	@return Types.Action<any>
]=]
function Store.get(action: Types.Action<any>): Types.Action<any>
	assert(typeof(action) == "table", "Action must be a table")
	assert(action.type, "Action must have an action type")
	assert(not isServer, "red.get() must be called from the client")

	local uid: string = Util.randomString(8)

	action.uid = uid
	action.method = "get"

	local connections: { RBXScriptConnection } = {}
	local res: Types.Action<any>?
	local responseReceived: boolean?

	local promise = Promise.new(function(resolve, _reject)
		connections[#connections + 1] = remotes.Client.OnClientEvent:Connect(
			function(_action: Types.Action<any>)
				if _action.method == "get_result" and _action.uid == uid then
					resolve(_action)
				end
			end
		)

		Store.dispatch(action)
	end)
		:andThen(function(result: Types.Action<any>)
			res = result
			responseReceived = true
		end)
		:catch(function(err: string)
			res = {
				err = err,
			} :: Types.Action<any>
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
		} :: Types.Action<any>
end

function Store._callSubscribers(action: Types.Action<any>)
	if not action.type or action.method == "get_result" then
		-- Ignore get_result action methods, these
		-- will be processed by store.get()
		return
	end

	signal:Fire(action)
end

--[=[
	Sets up a subscription to listen for actions dispatched by the store

	When an action is dispatched, the callback function will be called with the action as an argument

	When finished with the subscription, the connection should be disconnected
	```lua
	local connection: RBXScriptConnection = store.subscribe(function(action: red.Action)
		print(action.type)
	end)

	connection:Disconnect()
	```

	@within Store
	@method subscribe
	@param callback (action: Types.Action<any>) -> ()
	@return RBXScriptConnection
]=]
function Store.subscribe(callback: (action: Types.Action<any>) -> ()): RBXScriptConnection
	assert(
		typeof(callback) == "function",
		"Callback argument must exist and be a function"
	)

	if #_connections == 0 then
		-- If there are no connections, start listening for events

		if isServer then
			-- store.dispatch() called from client
			_connections[#_connections + 1] = remotes.Client.OnServerEvent:Connect(
				function(player: Player, action: Types.Action<any>)
					action.player = player

					Store._callSubscribers(action)
				end
			)
		else
			-- store.dispatch() called from server
			_connections[#_connections + 1] = remotes.Client.OnClientEvent:Connect(
				function(action: Types.Action<any>)
					Store._callSubscribers(action)
				end
			)
		end
	end

	return signal:Connect(callback)
end

--[=[
	Subscribes to specific action types

	```lua
	store.subscribeTo("HELLO_WORLD", function(action: red.Action)
		print(action.type)
	end)
	```

	```lua
	store.subscribeTo({ "HELLO_WORLD", "PING" }, function(action: red.Action)
		print(action.type)
	end)
	```

	When finished with the subscription, the connection should be disconnected
	```lua
	local connection: RBXScriptConnection = store.subscribeTo("HELLO_WORLD", function(action: red.Action)
		print(action.type)
	end)

	connection:Disconnect()
	```

	@within Store
	@method subscribeTo
	@param actionType { string } | string
	@param callback (action: Types.Action<any>) -> ()
	@return RBXScriptConnection
]=]
function Store.subscribeTo(
	actionType: { string } | string,
	callback: (action: Types.Action<any>) -> ()
): RBXScriptConnection
	if typeof(actionType) == "string" then
		actionType = { actionType }
	end

	local actionTypes = actionType :: { string }

	return Store.subscribe(function(action: Types.Action<any>)
		if table.find(actionTypes, action.type) then
			callback(action)
		end
	end)
end

return Store
