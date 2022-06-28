--[[
@name Promise
@version 1.0.0
@author dig1t

Variables
	Promise.status Current status of the promise
		pending The promise is waiting for a result
		fulfilled The promise was fulfilled successfully
		rejected The promise was rejected

Functions
	Promise.new(fn) => object Promise Constructs a new promise

Methods
	Promise:resolve(...) tuple Resolve a promise with tuple parameters
	Promise:reject(error) Reject a promise with a message
	Promise:destroy() Destroys the promise by clearing all private and public variables

Events
	Promise:thenDo(...) Called when the promise is fulfilled, if there are multiple fulfillment callbacks then
		then the result of the last callback will waterfall into the next callback, if the promise rejects during the
		callback waterfall, then it will stop waterfalling.
		The first callback will begin with the arguments from the resolution callback.
		The promise can be rejected until the last fulfillment callback is called.
	Promise:catch(error) Called when promise is rejected
	Promise:finally(fn) Similar to thenDo, finally will always be called at the end of the Promise
		and can only be set once, if the primose is rejected then the callback run with return no parameters

Examples
local promise -- Blank variable to allow rejection during a waterfall

promise = Promise.new(function(resolve, reject)
	wait(1)
	resolve(0)
end):thenDo(function(num)
	return num + 1
end):thenDo(function(num)
	promise:reject('error')
end):catch(function(err)
	warn(err)
end):finally(function(num)
	print('finally', promise.status)
	if promise.status ~= 'rejected' then
		print(num)
	end
end)
]]

local Promise, methods = {}, {}
methods.__index = methods

Promise.status = {
	pending = 'pending';
	fulfilled = 'fulfilled';
	rejected = 'rejected';
}

function methods:resolve(...)
	if self.status ~= Promise.status.pending then
		warn(string.format(
			'Cannot resolve a promise %s',
			self.status == Promise.status.rejected and 'after rejection' or 'more than once'
		))
		
		return
	end
	
	self._resultArgs = {...}
	
	local lastRes = self._resultArgs -- Start the callbacks with the initial resolution tuple
	
	for k, fn in ipairs(self._fulfillmentCallbacks) do
		-- Set lastRes to the returned argument from the last callback.
		lastRes = { fn(unpack(lastRes)) }
		
		if self.status ~= Promise.status.pending then
			break
		end
	end
	
	if self.status == Promise.status.pending then
		self.status = Promise.status.fulfilled
	end
	
	-- If defined, last result will be passed to the finally event.
	if self._onFinalizedCallback then
		self._onFinalizedCallback(unpack(lastRes))
	end
end

function methods:reject(...)
	if self.status ~= Promise.status.pending then
		warn(string.format(
			'Cannot reject a promise %s',
			self.status == Promise.status.fulfilled and 'after fulfillment' or 'more than once'
		))
		
		return
	end
	
	self.status = Promise.status.rejected
	self._resultArgs = {...}
	
	for k, fn in ipairs(self._rejectionCallbacks) do
		fn(...)
	end
	
	if self._onFinalizedCallback then
		self._onFinalizedCallback(...)
	end
end

function methods:thenDo(fn)
	assert(typeof(fn) == 'function', 'Must give a function to resolve')
	
	if self.status == Promise.status.fulfilled then
		fn(unpack(self._resultArgs))
		
		return self
	end
	
	self._fulfillmentCallbacks[#self._fulfillmentCallbacks + 1] = fn
	
	return self
end

function methods:catch(fn)
	assert(typeof(fn) == 'function', 'Must give a function to catching errors')
	
	if self.status == Promise.status.rejected then
		fn(unpack(self._resultArgs))
		
		return self
	end
	
	self._rejectionCallbacks[#self._rejectionCallbacks + 1] = fn
	
	return self
end

function methods:finally(fn)
	assert(not self._onFinalizedCallback, 'Only one finally callback can be used')
	assert(typeof(fn) == 'function', 'Must give a function for the finally callback')
	
	if self.status == Promise.status.fulfilled or self.status == Promise.status.rejected then
		fn(unpack(self._resultArgs))
		
		return self
	end
	
	self._onFinalizedCallback = fn
	
	return self
end

function methods:destroy()
	self._fulfillmentCallbacks = nil
	self._rejectionCallbacks = nil
	self._onFinalizedCallback = nil
	self._resultArgs = nil
	self.status = nil
end

function Promise.new(fn)
	assert(typeof(fn) == 'function', 'Must give a function to make a promise')
	
	local self = setmetatable({}, methods)
	
	self._fulfillmentCallbacks = {}
	self._rejectionCallbacks = {}
	
	self.status = Promise.status.pending
	
	coroutine.wrap(function()
		local success, err = pcall(
			fn,
			function(...)
				self:resolve(...)
			end,
			function(...)
				self:reject(...)
			end
		)
		
		if err and self.stauts == Promise.status.pending then
			self:reject(err)
		end
	end)()
	
	return self
end

return Promise
