--[[
-- Usage example
-- Server
local test = {}

test.name = 'test'
test.version = '1.0.0'
test.private = { -- Clients cannot invoke these
	'TEST_HELLO'
}

-- Begin Module Functions
test.ping = function(player, payload)
	store:dispatch(player, {
		type = 'TEST_PONG',
		payload = {
			clientTime = payload.clientTime
			responseTime = tick() - payload.clientTime
		}
	})
end

return test

-- Client
local store = red.Store.new()

store:subscribe(function(action)
	if action.type == 'TEST_PONG' then
		local t = tick()
		
		print('client to server time: ', action.payload.responseTime)
		print('server to client time: ', t - (action.payload.responseTime + payload.clientTime))
		print('client 2 server 2 client time: ', t - action.payload.clientTime)
	end
end)

store:dispatch({
	type = 'TEST_PING',
	payload = {
		clientTime = tick()
	}
})]]

local ReplicatedStorage = game:GetService('ReplicatedStorage')

local Constants = require(script.Parent.Constants)

local remotes = ReplicatedStorage[Constants.remoteFolderName]

local Server, methods = {}, {}
methods.__index = methods

function methods.error(err)
	error(err or '', 3)
end

function methods:sendError(err)
	methods.error(err)
	self:localCall('ANALYTICS_ERROR', {
		error = err
	})
end

function methods:bind(type, fn, private)
	assert(typeof(type) == 'string', 'Action type must be a string')
	assert(typeof(fn) == 'function', 'Action must be a function')
	
	self[private == true and '_privateActions' or '_actions'][type] = fn
end

function methods:unbind(id)
	assert(self._actions[id] or self._privateActions[id], 'Action does not exist')
	
	self._actions[id] = nil
	self._privateActions[id] = nil
end

function methods:loadModule(path)
	assert(typeof(path) == 'Instance' and path:IsA('ModuleScript'), 'Path is not a ModuleScript')
	
	local module = require(path)
	
	assert(module.name, 'Module does not have a name')
	
	--self._modules[module.name] = module.version or true
	
	-- Iterate through module and format action names
	-- to include the controller name
	-- and capitalize all characters
	for name, func in pairs(module) do
		if typeof(func) == 'function' then
			local actionType = string.upper(module.name) .. '_' .. string.upper(name)
			
			self:bind(
				actionType,
				func,
				typeof(module.private) == 'table' and module.private[actionType] or module.private == true
			)
		end
	end
end

function methods:loadModules(modules)
	for _, module in pairs(modules) do
		self:loadModule(module)
	end
end

-- Function for interal use only
-- Arguments will be interpreted as either (actionType, payload) or (actionType, player, payload)
function methods:localCall(actionType, ...)
	assert(typeof(actionType) == 'string', 'Action type must be a string')
	assert(self._actions[actionType] or self._privateActions[actionType], 'Action "' .. actionType .. '" does not exist')
	
	local success, res = pcall(self._actions[actionType] or self._privateActions[actionType], ...)
	
	if not success then
		self:sendError(actionType .. ': ' ..res)
	end
	
	if typeof(res) == 'table' and not res.err then
		res.success = true
	end
	
	return res
end

function methods:call(action, player)
	assert(action and typeof(action.type) == 'string', 'Action type must be a string')
	
	if not (self._actions[action.type] or self._privateActions[action.type]) then
		return
	elseif player and self._privateActions[action.type] then
		-- Player should not be calling a private action
		
		return --self:sendError(player.userId .. ' attempted to call a private action')
	end
	
	local args = {}
	
	table.insert(
		args,
		(player and player:IsA('Player') and player) or
		(action.player and action.player:IsA('Player') and action.player)
	) -- Check to make sure the player argument is a valid player
	
	if action.payload and typeof(action.payload) == 'table' then
		table.insert(args, action.payload)
	end
	
	local success, res = pcall(self._actions[action.type] or self._privateActions[action.type], args[1] and args[1], args[2] and args[2])
	
	if not success then
		self:sendError(res, typeof(args[1]) == 'Instance' and args[1]:IsA('Player') and args[1].UserId)
	end
	
	if typeof(res) == 'table' and not res.err and res.success == nil then
		res.success = true
	elseif not res then
		res = {
			success = true
		}
	end
	
	return res
end

function methods:init()
	-- Hook listeners
	
	-- store:dispatch() called from client
	remotes.Client.OnServerEvent:Connect(function(player, action)
		if action.method and action.method == 'get_result' then
			return
		end
		
		action.player = player
		
		local res = self:call(action, player)
		
		if not res then
			return
		end
		
		-- If the action's method is "get" fire it back
		-- to the sender
		if action.method and action.method == 'get' then
			assert(typeof(res) == 'table', action.type .. ' - Cannot return a ' .. typeof(res) .. ' type to a client.')
			
			res.uid = action.uid
			
			-- Change method to get result since
			-- the server is now firing the result
			-- to the client.
			res.method = 'get_result'
			
			remotes.Client:FireClient(player, res)
		end
	end)
	
	-- store:dispatch() called from server
	remotes.Server.Event:Connect(function(action)
		if action.method and action.method == 'get_result' then
			-- Ignore actions with get_result methods, these will
			-- always be routed back into this listener
			-- after calling remotes.Server:Fire()
			return
		end
		
		local res = self:call(action)
		
		if not res then
			return
		end
		
		-- If the action's method is "get" fire it back
		-- to the sender
		if action.method and action.method == 'get' then
			assert(typeof(res) == 'table', action.type .. ' - Cannot return a ' .. typeof(res) .. ' type to a client. Only tables can be returned.')
			
			res.uid = action.uid
			
			-- Change method to get result since
			-- the server is now firing the result
			-- to the client.
			res.method = 'get_result'
			
			remotes.Server:Fire(res)
		end
	end)
end

function Server.new()
	local self = setmetatable({}, methods)
	
	self._actions = {}
	self._privateActions = {}
	--self._modules = {}
	
	math.randomseed(os.clock() * 1e6)
	
	return self
end

return Server
