--[[
-- Usage example
-- Service
local test: typeof(Service.ServiceType) = Service.new({
	name = "test",
	version = "1.0.0",
	private = { -- Clients cannot invoke these
		"TEST_HELLO"
	}
})

-- all other services will have already
-- been loaded when this gets called
function test:init()
	print("red has started!")
end

function test:_privateMethod(player, payload)
	-- this cannot be called from anywhere except this service
end

function test:ping(player, payload)
	store:dispatch(player, {
		type = "TEST_PONG",
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
	if action.type == "TEST_PONG" then
		local t = tick()

		print("client to server time: ", action.payload.responseTime)
		print("server to client time: ", t - (action.payload.responseTime + payload.clientTime))
		print("client 2 server 2 client time: ", t - action.payload.clientTime)
	end
end)

store:dispatch({
	type = "TEST_PING",
	payload = {
		clientTime = tick()
	}
})
]]

--!strict

local Types = require(script.Parent.Types)

local Service: Types.ServiceClass = {} :: Types.ServiceClass
Service.__index = Service

function Service.new(config: Types.ServiceConfig): Types.ServiceType
	assert(config, "Config must be provided")
	assert(typeof(config) == "table", "Config must be a table")
	assert(config.name, "Config must have a name")

	if config.private then
		assert(
			typeof(config.private) == "table" or typeof(config.private) == "boolean",
			"Config.private must be a table or boolean"
		)
	end

	local self = setmetatable(config, Service)

	self._redService = true
	self._services = {}

	return self
end

return Service
