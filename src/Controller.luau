--[=[
@class Controller

Controller is a class that is used to manage different features of the game.
It can be ran on the client and server.

```lua
local controller = red.Controller.new({
	name = "test";
})

controller:init(function()
	print("init")
end)

-- You can subscribe to red actions through the controller
controller:subscribe(function(action: red.Action)
	print(action.type)
end)

-- You can also listen to the stepped event
controller:stepped(function(deltaTime: number)
	self.timeElapsed = self.time + deltaTime
	print(self.timeElapsed)
end)
```
]=]

--!strict

local RunService = game:GetService("RunService")

local Store = require(script.Parent.Store)
local Types = require(script.Parent.Types)
local Util = require(script.Parent.Parent.Util)

local Controller = {}
Controller.__index = Controller

-- Controller
export type ControllerConfig = {
	name: string,
	[any]: any,
}

export type ControllerType = typeof(setmetatable(
	{} :: {
		name: string,
		controllerId: string,
		redController: boolean,
		[any]: any,
	},
	Controller
))

local store = Store.new()

local controllers: { [string]: ControllerType } = {}
local storeSubscriptions: { [number]: string } = {}

local _subscriptionId: string = store:subscribe(function(action: Types.Action<any>)
	for _, controllerId: string in pairs(storeSubscriptions) do
		local controller: ControllerType = controllers[controllerId]

		if controller and controller.subscribe then
			controller:subscribe(action)
		end
	end
end)

RunService.Stepped:Connect(function(deltaTime: number)
	for _, controller: ControllerType in pairs(controllers) do
		if controller.stepped then
			controller:stepped(deltaTime)
		end
	end
end)

--[=[
Creates a new controller instance

@param config ControllerConfig
@return ControllerType
]=]
function Controller.new(config: ControllerConfig): ControllerType
	assert(typeof(config) == "table", "Expected config to be a table")
	assert(typeof(config.name) == "string", "Expected config.name to be a string")
	assert(
		not controllers[config.name],
		"Controller with name " .. config.name .. " already exists"
	)

	if config.init then
		assert(typeof(config.init) == "function", "Expected config.init to be a function")
	end

	if config.subscribe then
		assert(
			typeof(config.subscribe) == "function",
			"Expected config.subscribe to be a function"
		)
	end

	local self = setmetatable({}, Controller)

	self.name = config.name
	self.controllerId = Util.randomString()
	self.redController = true

	return self
end

--[=[
Called when the controller is initialized

@within Controller
@method Destroy
]=]
function Controller.Destroy(self: ControllerType)
	controllers[self.name] = nil

	local subscriptionIndex = table.find(storeSubscriptions, self.controllerId)

	if subscriptionIndex then
		table.remove(storeSubscriptions, subscriptionIndex)
	end
end

--[=[
Adds controller ModuleScripts from a folder or table

Setting a requiredSuffix will only add modules that end with the suffix.
(e.g. "Controller" will only add modules that end with "Controller")

This will call the ```init``` method on all controllers once they are added.

Call ```Controller.start()``` to call the ```ready``` method on all controllers.

@param _controllers Instance | { ModuleScript }
@param requiredSuffix string?
]=]
function Controller.addModules(
	_controllers: Instance | { ModuleScript },
	requiredSuffix: string?
)
	local modules: { ModuleScript } = {}

	if typeof(_controllers) == "Instance" then
		if requiredSuffix then
			local children: { Instance } = _controllers:GetDescendants()

			_controllers = {}

			for _, module: Instance in ipairs(children) do
				if
					module
					and module:IsA("ModuleScript")
					and module.Name:sub(-#requiredSuffix) == requiredSuffix
				then
					local _module: ModuleScript = module
					modules[#modules + 1] = _module
				end
			end
		else
			for _, child: Instance in ipairs(_controllers:GetChildren()) do
				if child and child:IsA("ModuleScript") then
					modules[#modules + 1] = child
				end
			end
		end
	elseif typeof(_controllers) == "table" then
		for _, module: ModuleScript in ipairs(_controllers) do
			assert(typeof(module) == "Instance", "Expected module to be an Instance")
		end
	end

	for _, module: ModuleScript in pairs(modules) do
		local newController: ControllerType = require(module) :: any

		if not newController.name then
			warn(`{module.Name} does not have a name`)
			continue
		end

		if newController.init then
			assert(
				typeof(newController.init) == "function",
				"Expected controller.init to be a function"
			)

			task.spawn(function()
				debug.setmemorycategory(newController.name)
				newController:init()
			end)
		end

		if newController.subscribe then
			storeSubscriptions[#storeSubscriptions + 1] = newController.controllerId
		end

		controllers[newController.name] = newController
	end
end

--- Calls the ```ready``` method on all controllers.
function Controller.start()
	for _, controller: ControllerType in pairs(controllers) do
		if not controller.ready then
			continue
		end

		assert(
			typeof(controller.ready) == "function",
			"Expected controller.ready to be a function"
		)

		task.spawn(function()
			debug.setmemorycategory(controller.name)
			controller:ready()
		end)
	end
end

--[=[
Gets a controller by name

@param name string
@return ControllerType?
]=]
function Controller.get(name: string): ControllerType?
	assert(typeof(name) == "string", "Expected name to be a string")

	if not controllers[name] then
		warn(`Controller with name {name} does not exist`)
	end

	return controllers[name]
end

return Controller
