--[=[
@class Service

Usage example

### Server
```lua
local test: Service.ServiceType = Service.new({
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

function test:_privateMethod(player: Player, payload: red.ActionPayload)
	-- this cannot be called from anywhere except this service
end

function test:ping(player: Player, payload: red.ActionPayload)
	store:dispatch(player, {
		type = "TEST_PONG",
		payload = {
			clientTime = payload.clientTime
			responseTime = workspace:GetServerTimeNow() - payload.clientTime
		}
	})
end

return test
```

### Client
```lua
local store = red.Store.new()

store:subscribe(function(action: red.Action)
	if action.type == "TEST_PONG" then
		local timeNow: number = workspace:GetServerTimeNow()

		print("client to server time: ", action.payload.responseTime)
		print("server to client time: ", timeNow - (action.payload.responseTime + payload.clientTime))
		print("client 2 server 2 client time: ", timeNow - action.payload.clientTime)
	end
end)

store:dispatch({
	type = "TEST_PING",
	payload = {
		clientTime = tick()
	}
})
```
]=]

--!strict

local Service = {}
Service.__index = Service

export type ServiceConfig = {
	name: string,
	private: { string } | boolean?,
	[any]: any,
}

export type ServiceType = typeof(setmetatable(
	{} :: {
		_redService: true,
		_services: {
			[string]: any,
		},
		name: string,
		[any]: any,
	},
	Service
))

--[=[
	Creates a new service instance
	
	@param config ServiceConfig
	@return ServiceType
]=]
function Service.new(config: ServiceConfig): ServiceType
	assert(config, "Config must be provided")
	assert(typeof(config) == "table", "Config must be a table")
	assert(config.name, "Config must have a name")

	if config.private then
		assert(
			typeof(config.private) == "table" or typeof(config.private) == "boolean",
			"Config.private must be a table or boolean"
		)
	end

	local self = setmetatable(config, Service) :: ServiceType

	self._redService = true
	self._services = {}

	return self
end

return Service
