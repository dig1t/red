-- src/ReplicatedStorage/red/Modules/State.lua

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local _ = require(ReplicatedStorage.red.Util)

local State = {}

function State.new(preloadedState)
	local self = {}
	
	local _state = preloadedState or {}
	local _listeners = {}
	
	function self:get()
		return _state
	end
	
	function self:listen(fn)
		if assert(typeof(fn) == 'function', 'Callback argument must be a function') then
			local id = _.randomString(8) -- Unique reference ID used for unsubscribing
			
			_listeners[id] = fn
			
			return id
		end
	end
	
	function self:unlisten(id)
		if assert(_listeners[id], 'State listener does not exist') then
			_listeners[id] = nil
		end
	end
	
	function self:pushUpdates(prevState)
		for k, callback in pairs(_listeners) do
			pcall(callback, prevState)
		end
	end
	
	function self:set(newState)
		local prevState = _.extend({}, _state)
		
		if typeof(newState) == 'function' then
			_state = newState(_state)
			self:pushUpdates(prevState)
		elseif typeof(newState) == 'table' then
			for k, v in pairs(newState) do
				_state[k] = v
			end
			
			self:pushUpdates(prevState)
		end
	end
	
	return setmetatable(self, {
		__index = function(tbl, k)
			return rawget(_state, k)
		end;
		
		__newindex = function(self, k, v)
			rawset(_state, k, v)
		end;
	})
end

return State