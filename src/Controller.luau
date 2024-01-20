--[[
-- @name Controller
-- @desc A Controller is a class that is used to manage different features of the game.
-- It runs separately on both the client and server.
-- @author dig1t

-- Controller methods
-- @method init: () -> nil - Called when the controller is initialized
-- @method subscribe: (action: Types.Action) -> nil - Called when a red action is dispatched
-- @method stepped: (deltaTime: number) -> nil - Called every frame
-- @method destroy: () -> nil - Destroys the controller

-- Controller config
-- @param name: string - The name of the controller
-- @param init: () -> nil - Called when the controller is initialized
-- @param subscribe: (action: Types.Action) -> nil - Called when a red action is dispatched
-- @param stepped: (deltaTime: number) -> nil - Called every frame

-- Controller functions
-- @function Controller.new: (config: Types.ControllerConfig) -> Types.ControllerType - Creates a new controller
-- @function Controller.get: (name: string) -> Types.ControllerType - Gets a controller by name
-- @function Controller.addModules: (_controllers: Instance | { ModuleScript }) -> nil - Adds controller ModuleScripts from a folder or table
-- @function Controller.start: () -> nil - Calls the ready method on all controllers

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
local Types = require(script.Parent.Types)

local Util = dLib.Util

local Controller: Types.ControllerClass = {} :: Types.ControllerClass
Controller.__index = Controller

local store = Store.new()

local controllers: { [string]: Types.ControllerType } = {}
local storeSubscriptions: { [number]: string } = {}

local _subscriptionId: string = store:subscribe(function(action: Types.Action)
	for _, controllerId: string in pairs(storeSubscriptions) do
		local controller: Types.ControllerType = controllers[controllerId]

		if controller and controller.subscribe then
			controller:subscribe(action)
		end
	end
end)

RunService.Stepped:Connect(function(deltaTime)
	for _, controller: Types.ControllerType in pairs(controllers) do
		if controller.stepped then
			controller:stepped(deltaTime)
		end
	end
end)

function Controller.new(config: Types.ControllerConfig): Types.ControllerType
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

function Controller:destroy(): nil
	controllers[self.name] = nil

	local subscriptionIndex = table.find(storeSubscriptions, self.controllerId)

	if subscriptionIndex then
		table.remove(storeSubscriptions, subscriptionIndex)
	end

	return nil
end

-- Setting suffix to true will make this function add ALL modules inside the folder
function Controller.addModules(_controllers: Instance | { ModuleScript }, suffix: string?): nil
	local modules: { ModuleScript } = {}

	if typeof(_controllers) == "Instance" then
		if suffix then
			local children: { Instance } = _controllers:GetDescendants()

			_controllers = {}

			for _, module: Instance in ipairs(children) do
				if module and module:IsA("ModuleScript") and module.Name:sub(-#suffix) == suffix then
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
		local newController: Types.ControllerType = require(module)

		if newController.init then
			assert(typeof(newController.init) == "function", "Expected controller.init to be a function")

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

	return nil
end

function Controller.start(): nil
	for _, controller: Types.ControllerType in pairs(controllers) do
		if controller.ready then
			assert(typeof(controller.ready) == "function", "Expected controller.ready to be a function")

			task.spawn(function()
				debug.setmemorycategory(controller.name)
				controller:ready()
			end)
		end
	end

	return nil
end

function Controller.get(name: string): Types.ControllerType
	if not controllers[name] then
		warn("Controller with name " .. name .. " does not exist")
	end

	return controllers[name]
end

return Controller
