--[[
-- Usage example

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

print('state destroyed?', not success) -- expect: true
]]

--!strict

local Util = require(script.Parent.Parent.dLib).Util
local Types = require(script.Parent.Types)

local State: Types.StateClass = {} :: Types.StateClass
State.__index = State

function State.new(initialState: { [any]: any }?): Types.StateType
	if initialState ~= nil then
		assert(typeof(initialState) == "table", "Expected initialState to be a table")
	end

	local self = setmetatable({
		__index = function(_self, key)
			return _self._context[key] or _self[key]
		end
	}, State)

	self._context = initialState or {}
	self._listeners = {} :: {
		[Types.SubscriptionId]: (prevState: any, newState: any) -> nil
	}

	return self
end

-- Number of first level children
function State:length(): number
	return Util.tableLength(self._context)
end

function State:get(path: string | boolean): any -- Todo: support for nested tables
	if not self._context then
		return nil
	end

	if typeof(path) == "number" then
		return self._context[path] -- Return the index, if exists
	end

	return path == true and self._context -- return the entire state
		or Util.treePath(self._context, path, ".") -- return the value at the path
end

function State:listen(callback: (prevState: any, newState: any) -> nil): Types.SubscriptionId?
	if not self._listeners then
		return nil
	end

	assert(typeof(callback) == "function", "Callback argument must be a function")

	-- Unique reference ID used for unsubscribing
	local subscriptionId: Types.SubscriptionId = Util.randomString(8)

	self._listeners[subscriptionId] = callback

	return subscriptionId
end

function State:unlisten(subscriptionId: Types.SubscriptionId): nil
	if not self._listeners then
		return nil
	end

	assert(self._listeners[subscriptionId], "State listener does not exist")

	self._listeners[subscriptionId] = nil

	return nil
end

function State:pushUpdates(prevState: any, newState: any): nil
	if not self._context or not self._listeners then
		return
	end

	local _newState = newState or self._context

	for _, callback in pairs(self._listeners) do
		pcall(callback, prevState, _newState)
	end

	return nil
end

function State:push(a: any, b: any): any
	if not self._context then
		return nil
	end

	local prevState = Util.extend({}, self._context) -- Create a 1 level copy // TODO: change to deep copy
	local key = b ~= nil and a or #self._context + 1

	self._context[key] = b ~= nil and b or a

	self:pushUpdates(prevState)

	return key
end

function State:reset(): nil
	self:pushUpdates(self._context, {})

	self._context = {}

	return nil
end

function State:set(newState: any, value: any): nil
	if not self._context then
		return nil
	end

	local prevState = Util.extend({}, self._context) -- Create a local copy // TODO: change to deep copy

	if typeof(newState) == "function" then
		-- Replace entire state with the result of newState()
		-- If newState() returns nil, the state will not be changed // TODO: change to nil instead of doing nothing?
		-- If the required value is nil, use State:reset()

		self._context = newState(self._context) or self._context
	elseif typeof(newState) == "table" then
		-- Replace specific state keys with given values

		for k, v in pairs(newState) do
			self._context[k] = v
		end
	elseif typeof(newState) == "string" then
		-- Set specified state path with given value
		-- This requires the second argument to be a
		-- value, unless the path is being set to nil

		local path = Util.split(newState, ".", true)
		local res = self._context

		if not res then
			return nil
		end

		-- Go through nest until the last nest level is reached
		for i, childName in ipairs(path) do
			local numberIndex = tonumber(childName)

			if numberIndex then
				childName = numberIndex
			end

			if res[childName] and i ~= #path then
				res = res[childName]
			elseif i == #path then
				-- Change the value if end of the path was reached
				res[childName] = value
			else
				break
			end
		end
	else
		warn("No valid state setter was given")
		return nil
	end

	self:pushUpdates(prevState)

	return nil
end

function State:remove(path: string): nil
	local prevState = Util.extend({}, self._context) -- Create a local copy
	local treePath = Util.split(path, ".", true)
	local res = self._context

	if not res then
		return nil
	end

	-- Dig through nest until the last nest level is reached
	for i, childName in ipairs(treePath) do
		local numberIndex = tonumber(childName)

		if numberIndex then
			childName = numberIndex
		end

		if res[childName] and i ~= #treePath then
			res = res[childName]
		elseif i == #treePath then
			-- Remove the value if end of the path was reached
			res[childName] = nil
		else
			break
		end
	end

	self:pushUpdates(prevState)

	return nil
end

function State:destroy(): nil
	self._context = nil
	self._listeners = nil

	setmetatable(self, {})

	return nil
end

return State
