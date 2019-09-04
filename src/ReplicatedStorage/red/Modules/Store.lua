-- src/ReplicatedStorage/red/Modules/Store.lua

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
local _ = require(ReplicatedStorage.red.Util)

local isServer = RunService:IsServer()
local remotes = ReplicatedStorage.red.Remotes

local Store = {}
local methods = {}

function Store.new()
	local self = {}
	
	self._subscribers = {}
	self.modules = {}
	
	-- Hook listeners
	if isServer then
		--[[App.remotes.server.OnServerEvent:Connect(function(action) -- may not be needed
			for k, callback in pairs(self._subscribers) do
				pcall(callback, action)
			end
		end)]]
		
		remotes.Client.OnServerEvent:Connect(function(player, action) -- Received event from client
			action.player = player
			
			for k, callback in pairs(self._subscribers) do
				pcall(callback, action)
			end
		end)
	else
		remotes.Client.OnClientEvent:Connect(function(action) -- Received event from the server
			for k, callback in pairs(self._subscribers) do
				-- Usage example
				-- store:subscribe(function(action) print(action.type) end)
				pcall(callback, action)
			end
		end)
	end
	
	return setmetatable(methods, {
		__index = self
	})
end

--[[
	@desc dispatches an action
	@param player|boolean arg[1] - determines who receives the action event (optional)
	@param object action arg[1]|arg[2] - action
]]--
function methods:dispatch(...)
	local args = {...}
	
	local action = #args == 1 and args[1] or args[2]
	
	local recipient = #args == 2 and typeof(args[1]) == 'Instance' and args[1]
	local fireToAll = #args == 2 and type(args[1]) == 'boolean' and args[1]
	
	if #args == 1 then
		if isServer then
			remotes.Server:Fire(action)
		else
			remotes.Client:FireServer(action)
		end
	elseif assert(#args == 2 and isServer, 'Dispatcher must be the server') then
		if recipient and not fireToAll then
			remotes.Client:FireClient(recipient, action)
		elseif fireToAll then
			remotes.Client:FireAllClients(action)
		elseif self.error then
			self.error('Store - could not dispatch action') -- Convert to error handler
		end
	end
end

--[[
	@desc dispatches an action
	@param object player - player object
	@param object location - teleport point
]]--
function methods:get(type, ...)
	if assert(type, 'Missing action type') then
		return isServer and script.call:InvokeClient(type, ...) or script.call:InvokeServer(type, ...)
	end
end

function methods:subscribe(fn)
	if assert(typeof(fn) == 'function', 'Callback argument must be a function') then
		local id = _.randomString(8) -- Unique reference ID used for unsubscribing
		
		self._subscribers[id] = fn
		
		return id
	end
end

function methods:unsubscribe(id)
	if assert(self._subscribers[id], 'Event listener does not exist') then
		self._subscribers[id] = nil
	end
end

return Store