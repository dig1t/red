--[=[
@class Server

The Server class is used to create a new server instance.

#### Setup
```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local red = require(ReplicatedStorage.Packages.red)

local server: red.ServerType = red.Server.new() -- Constructs a new server

server:init() -- Starts listening to dispatches
```
]=]

--!strict

local Store = require(script.Parent.Store)
local Types = require(script.Parent.Types)
local redUtil = require(script.Parent.redUtil)

local remotes = redUtil.getRemotes()
local store = Store.new()

local Server = {}
Server.__index = Server

export type ServerType = typeof(setmetatable(
	{} :: {
		_reducers: {
			[string]: (player: Player, payload: Types.ActionPayload<any>?) -> any,
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
	return setmetatable({
		_reducers = {},
		started = false,
		store = store,
	}, Server) :: ServerType
end

--[=[
Use this method to bind a reducer to the server.

Examples:
```lua
server:bind("ACTION_TYPE", function(player: Player, payload: Types.ActionPayload?)
	-- Do something
end)
```

```lua
server:bind("PLAYER_KILL", function(player)
	if player and player.Character then
		player.Character:BreakJoints()
	end
end, true)
```

@within Server
@method bind
@param actionType string
@param reducer () -> ()
]=]
function Server.bind(
	self: ServerType,
	actionType: string,
	reducer: (player: Player, payload: Types.ActionPayload<any>) -> ()
)
	assert(typeof(actionType) == "string", "Action type must be a string")
	assert(typeof(reducer) == "function", "Action must be a function")

	self._reducers[actionType] = reducer
end

--[=[
Use this method to unbind a handler from the server.

Example:
```lua
server:unbind("ACTION_TYPE")
```

@within Server
@method unbind
@param id string
]=]
function Server.unbind(self: ServerType, id: string)
	assert(self._reducers[id], "Action reducer does not exist")

	self._reducers[id] = nil
end

--[=[
Use this method to load a handler into the server.

Example:
```lua
server:useHandler(game.ServerScriptService.Server.ActionHandlers.Players)
```

@within Server
@method useHandler
@param moduleInstance ModuleScript
]=]
function Server.useHandler(self: ServerType, moduleInstance: ModuleScript)
	assert(
		typeof(moduleInstance) == "Instance" and moduleInstance:IsA("ModuleScript"),
		"Path is not a ModuleScript"
	)

	local handler = require(moduleInstance) :: any

	assert(typeof(handler) == "function", "Handler must be a function")

	debug.setmemorycategory(`Action Handler: {handler.Name}`)
	handler(self)
end

--[=[
Use this method to load multiple handlers modules into the server.

Example:
```lua
server:useHandlers(game.ServerScriptService.Server.Handlers:GetChildren())
```

@within Server
@method useHandlers
@param handlers { ModuleScript }
]=]
function Server.useHandlers(self: ServerType, handlers: { ModuleScript } | Instance)
	for _, handler: ModuleScript in
		pairs(
			typeof(handlers) == "Instance" and handlers:GetChildren()
				or handlers :: { ModuleScript }
		)
	do
		self:useHandler(handler)
	end
end

--[=[
Use this method to call an action.

Example:
```lua
server:_call(action, player)
```

@within Server
@method _call
@param action Types.Action<any>
@param player Player?
@return Types.Action<any>
]=]
function Server._call(
	self: ServerType,
	action: Types.Action<any>,
	player: Player
): Types.Action<any>
	assert(action and typeof(action.type) == "string", "Action type must be a string")

	if not self._reducers[action.type] then
		return {
			type = action.type,
			err = "Action does not exist",
			success = false,
		} :: Types.Action<any>
	end

	local success: boolean, res: Types.Action<any> | string =
		pcall(self._reducers[action.type], player, action.payload)

	if not success then
		task.spawn(function()
			local userId: number = player.UserId

			if typeof(res) == "string" then
				error(res .. (userId and ` - UserId: {userId}` or ""), 2)
			end
		end)

		return {
			type = action.type,
			err = typeof(res) == "string" and res or nil,
			success = false,
		} :: Types.Action<any>
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

	return res :: Types.Action<any>
end

--[=[
Initializes the server.

@within Server
@method listen
]=]
function Server.listen(self: ServerType)
	-- store:dispatch() called from client
	remotes.Client.OnServerEvent:Connect(
		function(player: Player, action: Types.Action<any>)
			if action.method and action.method == "get_result" then
				return
			end

			local res: Types.Action<any> = self:_call(action, player)

			-- If the action's method is "get" fire it back
			-- to the sender
			if action.method and action.method == "get" then
				assert(
					typeof(res) == "table",
					action.type
						.. " - Cannot return a "
						.. typeof(res)
						.. " type to a client."
				)

				-- Change method to get result since
				-- the server is now firing the result
				-- to the client.
				res.method = "get_result"
				res.uid = action.uid

				remotes.Client:FireClient(player, res)
			end
		end
	)

	self.started = true
end

--[=[
Use this method to dispatch an action to the store from a handler

Example:
```lua
server:dispatch({
	type = "ACTION_TYPE",
	payload = {
		-- Payload
	}
})
```

@within Server
@method dispatch
@param ... any
]=]
function Server.dispatch(_, ...)
	store:dispatch(...)
end

return Server
