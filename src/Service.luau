--[=[
@class Service

Usage example (Type checking and intellisense compatible):

```lua
--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local red = require(Packages.red)

-- You can require other services as well!
local MyService = require(script.Parent.MyService)

local store = red.Store.new()

local Test = {
	name = "test",
	version = "1.0.0",
	private = { -- Clients cannot invoke these
		"TEST_HELLO"
	}
}
Test.__index = Test

-- This allows you to use Luau LSP for type checking and intellisense
export type TestServiceType = typeof(setmetatable(
	{} :: {
		-- Enter your properties here
		prop: string,
	},
	Test -- This is the service class
))

-- all other services will have already
-- been loaded when this gets called
function test.init(self: TestServiceType)
	self.prop = 1

	print("red has started!")

	print(MyService.property)
end

function test._privateMethod(self: TestServiceType, player: Player, payload: red.ActionPayload)
	-- this cannot be called from anywhere except this service
	print("called from ping")
end

function test.ping(self: TestServiceType, player: Player, payload: red.ActionPayload)
	print(self.prop)
	
	self:_privateMethod(player, payload)
	
	store:dispatch(player, {
		type = "TEST_PONG",
		payload = {
			clientTime = payload.clientTime
			responseTime = workspace:GetServerTimeNow() - payload.clientTime
		}
	})
end

return red.Service.new(Test) :: TestServiceType
```

### Client
```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local red = require(Packages.red)

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

export type ServiceClass = {
	name: string,
	private: { string } | boolean?,
	[any]: any,
}

export type ServiceType = typeof(setmetatable(
	{} :: {
		_redService: true,
		_methods: {
			[string]: any,
		},
		name: string,
		[any]: any,
	},
	Service
))

--[=[
	Creates a new service instance
	
	@param serviceClass ServiceClass
	@return ServiceType
]=]
function Service.new(serviceClass: ServiceClass): ServiceType
	assert(serviceClass, "Config must be provided")
	assert(typeof(serviceClass) == "table", "Config must be a table")
	assert(serviceClass.name, "Config must have a name")

	serviceClass.__index = serviceClass

	if serviceClass.private then
		assert(
			typeof(serviceClass.private) == "table" or typeof(serviceClass.private) == "boolean",
			"Config.private must be a table or boolean"
		)
	end

	local self = setmetatable(serviceClass, Service) :: ServiceType

	self._redService = true
	self._methods = {}

	return self
end

return Service
