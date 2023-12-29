--[[
-- @name Controller
-- @desc A Controller is a class that is used to manage different features of the game.
-- It runs separately on both the client and server.
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
local redTypes = require(script.Parent.redTypes)

local Util = dLib.import("dLib/Util")

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

	local newController = setmetatable({
		name = config.name;
		controllerId = Util.randomString();
		redController = true;
	}, { __index = Controller })

	return newController
end

function Controller:destroy()
	controllers[self.controllerId] = nil
	storeSubscriptions[self.controllerId] = nil
end

-- Setting suffix to true will make this function add ALL modules inside the folder
function Controller.addModules(_controllers: Instance | { ModuleScript }, suffix: string?)
	if typeof(_controllers) == "Instance" then
		if suffix then
			local children = _controllers:GetDescendants()

			_controllers = {}

			for _, module: ModuleScript in pairs(children) do
				if module:IsA("ModuleScript") and module.Name:sub(-#suffix) == suffix then
					_controllers[#_controllers + 1] = module
				end
			end
		else
			_controllers = _controllers:GetChildren()
		end
	end

	assert(typeof(_controllers) == "table", "Expected Controllers to be a table or Folder of ModuleScripts")

	for _, module in pairs(_controllers) do
		if typeof(module) == "Instance" and module:IsA("ModuleScript") then
			local newController = require(module)

			if newController.init then
				newController:init()
			end

			if newController.subscribe then
				storeSubscriptions[#storeSubscriptions + 1] = newController.controllerId
			end

			controllers[newController.name] = newController
		end
	end
end

function Controller.start()
	for _, controller: redTypes.ControllerType in pairs(controllers) do
		if controller.ready then
			controller:ready()
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
