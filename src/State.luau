--[=[
@class State

Usage example

```luau
local state = State.new({
	val = 1,
	time = tick(),
	nest = {
		val = 123123
	}
})

state:listen(function(prevState, newState)
	print(prevState, newState)
end)

state:set("val", 11)

print(state:length()) -- expect 3

state:set(function(prevState)
	prevState.val = 111

	return prevState
end)

state:set({
	val = 1111
})

state.val = 11111

state:remove("val") -- Removes val from the state

state:reset()

state:destroy()

local success = pcall(function()
	state:set("val", 1)
end)

print("state destroyed:", not success) -- expect: state destroyed: true
```
]=]

--!strict

local Types = require(script.Parent.Types)
local Util = require(script.Parent.Parent.Util)

local State = {}
State.__index = State

export type StateType = typeof(setmetatable(
	{} :: {
		_context: { [any]: any }?,
		_listeners: {
			[Types.SubscriptionId]: (prevState: any, newState: any) -> nil,
		}?,
	},
	State
))

--[=[
	Creates a new state instance

	@param initialState { [any]: any }? -- Initial state values
	@return StateType
]=]
function State.new(initialState: { [any]: any }?): StateType
	if initialState ~= nil then
		assert(typeof(initialState) == "table", "Expected initialState to be a table")
	end

	local self = setmetatable(
		{
			__index = function(_self, key)
				return _self._context[key] or _self[key]
			end,
		} :: any,
		State
	) :: StateType

	self._context = initialState or {}
	self._listeners = {} :: {
		[Types.SubscriptionId]: (prevState: any, newState: any) -> nil,
	}

	return self
end

-- Number of first level children

--[=[
	Returns the length of the state
	
	Example:
	```luau
	local state = State.new({
		val = 1,
		time = tick(),
		nest = {
			val = 123123
		}
	})
	
	print(state:length()) -- expect 3
	```

	@within State
	@method length
	@return number
]=]
function State.length(self: StateType): number
	return self._context and Util.tableLength(self._context) or 0
end

--[=[
	Returns the value at the given path

	Example:
	```luau
	local state = State.new({
		val = 1,
		time = tick(),
		nest = {
			val = 123123
		}
	})
	
	print(state:get("val")) -- expect 1
	print(state:get("nest.val")) -- expect 123123
	
	-- True as the argument returns the entire state
	print(state:get(true)) -- expect { val = 1, time = tick(), nest = { val = 123123 } }
	```

	@within State
	@method get
	@param path string | number | boolean
	@return any
]=]
function State.get(self: StateType, path: string | number | boolean): any -- Todo: support for nested tables
	if not self._context then
		return nil
	end

	if typeof(path) == "number" then
		return self._context[path] -- Return the index, if exists
	end

	return path == true and self._context -- return the entire state
		or (typeof(path) == "string" and Util.treePath(self._context, path, "."))
		or nil
end

--[=[
	Listens for state changes

	Example:
	```luau
	local state = State.new({
		val = 1,
		time = tick(),
		nest = {
			val = 123123
		}
	})
	
	state:listen(function(prevState, newState)
		print(prevState, newState)
	end)
	```

	@within State
	@method listen
	@param callback (prevState: any, newState: any) -> nil
	@return SubscriptionId?
]=]
function State.listen(self: StateType, callback: (prevState: any, newState: any) -> ()): Types.SubscriptionId?
	if not self._listeners then
		return
	end

	assert(typeof(callback) == "function", "Callback argument must be a function")

	-- Unique reference ID used for unsubscribing
	local subscriptionId: Types.SubscriptionId = Util.randomString(8)

	self._listeners[subscriptionId] = callback

	return subscriptionId
end

--[=[
	Unlistens for state changes

	Example:
	```luau
	local state = State.new({
		val = 1,
		time = tick(),
		nest = {
			val = 123123
		}
	})
	
	local subscriptionId = state:listen(function(prevState, newState)
		print(prevState, newState)
	end)
	
	state:unlisten(subscriptionId)
	```

	@within State
	@method unlisten
	@param subscriptionId SubscriptionId
]=]
function State.unlisten(self: StateType, subscriptionId: Types.SubscriptionId)
	if not self._listeners then
		return
	end

	assert(self._listeners[subscriptionId], "State listener does not exist")

	self._listeners[subscriptionId] = nil
end

function State.pushUpdates(self: StateType, prevState: any, newState: any)
	if not self._context or not self._listeners then
		return
	end

	local _newState = newState or self._context

	for _, callback in pairs(self._listeners) do
		pcall(callback, prevState, _newState)
	end
end

--[=[
	Pushes a new value to the state

	Example:
	```luau
	local state = State.new({
		val = 1,
		time = tick(),
		nest = {
			val = 123123
		}
	})
	
	state:push("val", 2)
	```

	@within State
	@method push
	@param keyOrValue any -- The key of the pushed value or the value itself if the state is an array
	@param value any? -- The value to push
	@return any -- The key of the pushed value
]=]
function State.push(self: StateType, keyOrValue: any, value: any?): any
	if not self._context then
		return
	end

	local prevState = Util.extend({}, self._context) -- Create a 1 level copy -- TODO: change to deep copy
	local key: any = value ~= nil and keyOrValue or #self._context + 1

	self._context[key] = value ~= nil and value or keyOrValue

	self:pushUpdates(prevState)

	return key
end

--[=[
	Resets the state to an empty table

	Example:
	```luau
	local state = State.new({
		val = 1,
		time = tick(),
		nest = {
			val = 123123
		}
	})
	
	state:reset()
	
	state:get(true) -- expect {}
	```

	@within State
	@method reset
]=]
function State.reset(self: StateType)
	self:pushUpdates(self._context, {})

	self._context = {}
end

--[=[
	Sets the state with a new value

	Example:
	```luau
	local state = State.new({
		val = 1,
		time = tick(),
		nest = {
			val = 123123
		}
	})
	
	state:set("val", 11) -- Change val to 11
	
	state:set(function(prevState)
		prevState.val = 111
		
		return prevState
	end) -- Change val to 111
	
	state:set({
		val = 1111
	}) -- Change val to 1111
	
	state:set("nest.val", 11111) -- Change nest.val to 11111
	
	state:set("undefinedNest.val", 11111) -- Create undefinedNest and set val to 11111
	```

	@within State
	@method set
	@param newState any -- The new state value
	@param value any? -- The value to set
]=]
function State.set(self: StateType, newState: any, value: any)
	if not self._context then
		return
	end

	local prevState = Util.extend({}, self._context) -- Create a local copy -- TODO: change to deep copy

	if typeof(newState) == "function" then
		-- Replace entire state with the result of newState()
		-- If newState() returns nil, the state will not be changed -- TODO: change to nil instead of doing nothing?
		-- If the required value is nil, use State:reset()

		self._context = newState(self._context) or self._context
	elseif typeof(newState) == "table" then
		-- Replace specific state keys with given values

		for k: any, v: any in pairs(newState) do
			self._context[k] = v
		end
	elseif typeof(newState) == "string" then
		-- Set specified state path with given value
		-- This requires the second argument to be a
		-- value, unless the path is being set to nil

		local path: { string } = Util.split(newState, ".", true)
		local res = self._context

		if not res then
			return
		end

		-- Go through nest until the last nest level is reached
		for i: number, childName: string in path do
			local numberIndex: number? = tonumber(childName)
			local resIndex: number | string = numberIndex or childName

			if res[resIndex] and i ~= #path then
				res = res[resIndex]
			elseif i == #path then
				-- Change the value if end of the path was reached
				res[resIndex] = value
			else
				break
			end
		end
	else
		warn("No valid state setter was given")
		return
	end

	self:pushUpdates(prevState)
end

--[=[
	Removes a value from the state

	Example:
	```luau
	local state = State.new({
		val = 1,
		time = tick(),
		nest = {
			val = 123123
		}
	})
	
	state:remove("val") -- Removes val from the state
	
	state:get(true) -- expect { time = tick(), nest = { val = 123123 } }
	```

	@within State
	@method remove
	@param path string | number -- The path to the value to remove
]=]
function State.remove(self: StateType, path: string | number)
	local prevState = Util.extend({}, self._context or {}) -- Create a local copy
	local treePath = Util.split(tostring(path), ".", true)
	local res = self._context

	if not res then
		return
	end

	-- Dig through nest until the last nest level is reached
	for i: number, childName: string in treePath do
		local numberIndex: number? = tonumber(childName)
		local resIndex: number | string = numberIndex or childName

		if res[resIndex] and i ~= #treePath then
			res = res[resIndex]
		elseif i == #treePath then
			-- Remove the value if end of the path was reached
			res[resIndex] = nil
		else
			break
		end
	end

	self:pushUpdates(prevState)
end

--[=[
	Destroys the state

	Example:
	```luau
	local state = State.new({
		val = 1,
		time = tick(),
		nest = {
			val = 123123
		}
	})
	
	state:destroy()
	
	local success = pcall(function()
		state:set("val", 1)
	end)
	
	print('state destroyed?', not success) -- expect: true
	```

	@within State
	@method destroy
]=]
function State.destroy(self: StateType)
	self._context = nil
	self._listeners = nil

	pcall(setmetatable, self, {})
end

--[=[
	Alias for State.destroy

	@within State
	@method Destroy
]=]
function State.Destroy(self: StateType)
	self:destroy()
end

return State
