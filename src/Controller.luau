--[[
-- Usage example

local controller = red.Controller.new({
	name = "test";
})

controller:init(function()
	print("init")
end)

controller:redSubscribe(function(action)
	print(action.type)
end)

controller:stepped(function(deltaTime)
	self.timeElapsed = self.time + deltaTime
	print(self.timeElapsed)
end)
]]

--!strict

local RunService = game:GetService("RunService")

local dLib = require(script.Parent.Parent.dLib)
local Store = require(script.Parent.Store)
local redTypes = require(script.Parent.redTypes)
local Util = dLib.import("Util")

local Controller: redTypes.ControllerType = {}

local store = Store.new()

local controllers: { [string]: redTypes.ControllerType } = {}
local storeSubscriptions: { [number]: string } = {}
local initiated: boolean = false

store:subscribe(function(action)
	for _, controllerId: string in pairs(storeSubscriptions) do
		local controller: redTypes.ControllerType = controllers[controllerId]
		
		if controller and controller.redSubscribe then
			controller:redSubscribe(action)
		end
	end
end)

RunService.Stepped:Connect(function(deltaTime)
	for _, controller: redTypes.ControllerType in pairs(controllers) do
		if controller.stepped then
			controller:stepped(deltaTime)
		end
	end
end)

function Controller.new(config: redTypes.ControllerConfig): redTypes.ControllerType
	assert(typeof(config) == "table", "Expected config to be a table")
	assert(typeof(config.name) == "string", "Expected config.name to be a string")
	assert(
		not controllers[config.name],
		"Controller with name " .. config.name .. " already exists"
	)
	
	if config.init then
		assert(typeof(config.init) == "function", "Expected config.init to be a function")
	end
	
	if config.redSubscribe then
		assert(
			typeof(config.redSubscribe) == "function",
			"Expected config.redSubscribe to be a function"
		)
	end
	
	local self = setmetatable({
		name = config.name;
		controllerId = Util.randomString();
		redController = true;
	}, { __index = Controller })
	
	return self
end

function Controller:destroy()
	controllers[self.controllerId] = nil
	storeSubscriptions[self.controllerId] = nil
end

function Controller.addControllerModules(_controllers: Instance | { ModuleScript })
	_controllers = typeof(_controllers) == "Instance" and _controllers:GetChildren() or _controllers
	
	assert(typeof(_controllers) == "table", "Expected a table or Instance")
	
	for _, module in pairs(_controllers) do
		if typeof(module) == "Instance" and module:IsA("ModuleScript") then
			local controller: redTypes.ControllerType = require(module)
			controller.__index = controller
			
			assert(controller.name, "Controller is missing a name")
			assert(
				not controllers[controller.controllerId],
				"Controller with name " .. controller.name .. " already exists"
			)
			assert(controller.controllerId, "Controller is missing a controllerId.")
			assert(controller.redController, "Controller is not a red Controller.")
			
			local newController: redTypes.ControllerType = setmetatable({}, controller)
			
			controllers[newController.controllerId] = newController
		end
	end
end

function Controller.initControllers()
	for _, controller: redTypes.ControllerType in pairs(controllers) do
		if controller.init then
			controller:init()
		end
		
		if controller.redSubscribe then
			storeSubscriptions[#storeSubscriptions + 1] = controller.controllerId
		end
	end
end

return Controller