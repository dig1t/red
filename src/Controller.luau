--[[
-- red Controller
-- @desc A Controller is a class that is used to manage different features of the game.
-- it runs separately on both the client and server.
-- @author dig1t

-- Controller methods
-- @method init: () -> nil - Called when the controller is initialized
-- @method subscribe: (action: redTypes.Action) -> nil - Called when a red action is dispatched
-- @method stepped: (deltaTime: number) -> nil - Called every frame
-- @method destroy: () -> nil - Destroys the controller

-- Controller config
-- @param name: string - The name of the controller
-- @param init: () -> nil - Called when the controller is initialized
-- @param subscribe: (action: redTypes.Action) -> nil - Called when a red action is dispatched
-- @param stepped: (deltaTime: number) -> nil - Called every frame

-- Controller functions
-- @function Controller.new: (config: redTypes.ControllerConfig) -> redTypes.ControllerType - Creates a new controller
-- @function Controller.get: (name: string) -> redTypes.ControllerType - Gets a controller by name
-- @function Controller.addControllerModules: (_controllers: Instance | { ModuleScript }) -> nil - Adds controllers from a folder or table

-- Usage example

local controller = red.Controller.new({
	name = "test";
})

controller:init(function()
	print("init")
end)

-- You can subscribe to red store to listen for actions
controller:subscribe(function(action)
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

store:subscribe(function(action)
	for _, controllerId: string in pairs(storeSubscriptions) do
		local controller: redTypes.ControllerType = controllers[controllerId]
		
		if controller and controller.subscribe then
			controller:subscribe(action)
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
	
	if config.subscribe then
		assert(
			typeof(config.subscribe) == "function",
			"Expected config.subscribe to be a function"
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
			
			if newController.init then
				newController:init()
			end
			
			if newController.subscribe then
				storeSubscriptions[#storeSubscriptions + 1] = newController.controllerId
			end
			
			controllers[newController.controllerId] = newController
		end
	end
end

function Controller.get(name: string): redTypes.ControllerType
	if not controllers[name] then
		warn("Controller with name " .. name .. " does not exist")
	end
	
	return controllers[name]
end

return Controller