--[[
-- Usage example

local state = red.State.new({
	val = 1,
	time = tick(),
	nest = {
		val = 123123
	}
})

state:listen(function(prevState, newState)
	print(prevState.val, newState.val)
end)

-- Module
local module = {}

function module.fn(_state)
	_state:get('nest.val')
end

return module
]]

local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Util = require(ReplicatedStorage.Lib.Util)

local State = {}

function State.new(initialState)
	local _context = initialState or {}
	local _listeners = {}
	
	local self = {}
	--self.__index = self
	
	self.__index = function(self, key)
		return _context[key] or self[key]
	end
	
	--[[local self = setmetatable({}, {
		__index = function(tbl, k)
			return rawget(_context, k)
		end;
		
		__newindex = function(self, k, v)
			rawset(_context, k, v)
		end;
	})]]
	
	function self:length()
		return Util.tableLength(_context)
	end
	
	function self:get(path) -- Todo: support for nested tables
		if typeof(path) == 'number' then
			return _context[path] -- Return the index, if exists
		end
		
		return path == true and _context or Util.treePath(_context, path, '.')
		--return key and _context[key] or (key == true and _context)
	end
	
	function self:listen(fn)
		assert(typeof(fn) == 'function', 'Callback argument must be a function')
		
		local id = Util.randomString(8) -- Unique reference ID used for unsubscribing
		
		_listeners[id] = fn
		
		return id
	end
	
	function self:unlisten(id)
		assert(_listeners[id], 'State listener does not exist')
		
		_listeners[id] = nil
	end
	
	function self:pushUpdates(prevState)
		for _, callback in pairs(_listeners) do
			pcall(callback, prevState, _context)
		end
	end
	
	function self:push(a, b)
		local prevState = Util.extend({}, _context)
		local key = b ~= nil and a or #_context + 1
		
		_context[key] = b ~= nil and b or a
		
		self:pushUpdates(prevState)
		
		return key
	end
	
	function self:reset()
		_context = {}
	end
	
	function self:set(newState, value)
		local prevState = Util.extend({}, _context) -- Create a local copy
		
		if typeof(newState) == 'function' then
			_context = newState(_context) or _context
		elseif typeof(newState) == 'table' then
			for k, v in pairs(newState) do
				_context[k] = v
			end
		elseif typeof(newState) == 'string' then
			local path = Util.split(newState, '.', true)
			local res = _context
			
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
			return
		end
		
		self:pushUpdates(prevState)
	end
	
	function self:remove(path)
		local prevState = Util.extend({}, _context) -- Create a local copy
		
		local treePath = Util.split(path, '.', true)
		local res = _context
		
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
	end
	
	return setmetatable({}, { __index = self })
end

return State