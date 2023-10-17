# Installing
## wally
Add the below line to your wally.toml file
```toml
red = "dig1t/red@1.1.7"
```
## Roblox Studio
Download the rbxm file from the [releases](https://github.com/dig1t/red/releases) tab and insert it into ReplicatedStorage or your location of choice.

# Documentation

## Server Class

### Server.new()
Returns a new Server class

#### Setup
```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local red = require(ReplicatedStorage.Packages.red)

local server = red.Server.new() -- Constructs a new server

server:init() -- Starts listening to dispatches
```

#### Module Setup
```lua
local module = {}

module.name = "module" -- Action prefix for binding actions
module.version = "1.0.0" -- For your records
module.private = { -- Functions not available to clients
	"MODULE_PRINT"
}

-- module.print will be binded as MODULE_SCRIPT
-- by using module.name as the prefix
module.print = function(payload)
	-- Payload can be missing
	-- Check for payload and the message being received
	if payload and payload.message then
		print(payload.message)
	end
end

module.hello = function(player, payload)
	print(string.format(
		"%s said %s.",
		player.Name,
		payload and payload.message or "hello"
	))
end

return module
```

#### Server:bind(type, fn, private)
`Server:bind(actionType, callback, [private]) -> void`

Binds an action to the server

If `private` is true, clients will be unable to dispatch this action.
```lua
server:bind("PLAYER_KILL", function(player)
	if player and player.Character then
		player.Character:BreakJoints()
	end
end, true)
```

#### Server:unbind(actionType)
`Server:unbind(actionType) -> void`

Unbinds an action from the server


#### Server:loadModule(path)
`Server:loadModule(path) -> void`

 Loads a module to bind to the server.
 `path` must be a ModuleScript instance

#### Server:loadModules(modules)
`Server:loadModules(modules) -> void`

 Loads a module to bind to the server.
 `modules` must be a table of ModuleScripts to load

#### Server:localCall(actionType, ...)
`Server:localCall(actionType, [...]) -> action`

Calls actions locally and returns an action as a response.
Tuple parameters can be passed in this order: `player, payload`
```lua
local Players = game:GetService("Players")

server:localCall("PLAYER_KILL", Players.Player1)
```

## Store Class
#### Store.new()
Returns a new Store class

#### Setup
```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local red = require(ReplicatedStorage.Packages.red)

local store = red.Store.new() -- Constructs a new store
```

#### Store:dispath(true|player(s)|(action), action)
`Store:dispatch(true|player(s)|(action), [action]) -> void`

Dispatches an action
- If only one argument is defined, then the server will recieve the dispatch.
- If two actions are defined, the defined client(s) will recieve the dispatch.

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

#### Store:get(action)
`Store:get(action) -> void`

Dispatches an action and yields until a result is returned.

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
end
```

#### Store:subscribe(callback)
`Store:subscribe(callback) -> connectionId`

Listens for all dispatches sent to the client, if used in a Script, it will only listen to server dispatches.
It will return a unique connection ID used for disconnecting the connection.

```lua
-- Clients and Servers use the same method
store:subscribe(function(action)
	if action.type == "UI_NOTIFICATION" then
		print(action.payload.message)
	end
end)
```

#### Store:unsubscribe(connectionId)
`Store:unsubscribe(connectionId) -> void`

Disconnects the connection so no further callbacks are made.

```lua
-- Setup the listener
local connectionId

connectionId= store:subscribe(function(action)
	if action.type == "HELLO_WORLD" then
		print(action.type)
		store:unsubscribe(connectionId) -- Stop receiving actions
	end
end)

wait(2)
store:unsubscribe(connectionId) -- Stop receiving actions
```

## State Class
### State.new([initialState])
Returns a new State class. An `initialState` table can be passed as the initial state.

#### Setup
```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local red = require(ReplicatedStorage.Packages.red)

local state = red.State.new() -- Constructs a new state
```

#### State:length()
`State:length() -> tableLength`

Returns the number of children in the state

#### State:get(path)
`State:get(path) -> result`

Gets a value from the state. This value can be
nested, if true is passed for `path`, the entire state will be returned

```lua
print(state:get("Player1.kills")) -- Prints player kills
print(true) -- Prints the whole state table
```

#### State:listen(callback)
`State:listen(callback) -> connectionId`

Watches for changes in the state. It will return a unique connection ID used for disconnecting the connection.
```lua
state:listen(function(prevState, newState)
	if prevState.Player1.position ~= newState.Player1.position then
		print("Character moved positions")
	end
end)
```

#### State:unlisten(connectionId)
`State:unlisten(connectionId) -> void`

Disconnects the connection so no further callbacks are made.

#### State:push(key, value)
`State:push(key, [value]) -> void`

Pushes/replaces a value to the state.

- If only one parameter is given,
the first parameter will be the value, and the index will be the # of
children in the state.
- If there are 2 parameters given, then the first parameter
will be the key, followed by the value

#### State:reset()
`State:reset() -> void`

Clears the state of all children

#### State:set(newState|path, value)
`State:set(newState, [value]) -> void`

Sets value(s) in the state.
- If both `path` and `value` are passed. `State:set()` will assume you are setting the given index `path` valued as `value`.
- If `newState` is a function, it will set the state as whatever the function returns. `State:Set()` will call the function with the current state as the first argument.

```lua
State:set("Player1.name", "Bob")
print(state.Player1.name) -- Bob

State:set(function(state)
	state.Player1.Name = "Jack"
	return state -- Return the modified state back
end)

print(state.Player1.name) -- Jack
```

#### State:remove(path)
`State:remove(path) -> void`

Removes a value from the state with the location of `path`.

```lua
state:remove("Player1.weapons.sword")
```

## Games powered by red

<a href="https://www.roblox.com/games/4771858173/Survival-Islands"><img width=49% src="https://i.imgur.com/Y9dYTWF.png"></a>
<a href="https://www.roblox.com/games/4693424588/Zombie-Task-Force"><img width=49% src="https://i.imgur.com/P4U5zls.png"></a>
<a href="https://www.roblox.com/games/90267357/Murder-Escape"><img width=49% src="https://i.imgur.com/hp4zts7.png"></a>
