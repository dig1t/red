--!strict

-- local redTypes = require(script.redTypes)
local redUtil = require(script.redUtil)

local red = {}

red.remotes = redUtil.getRemotes()

red.Server = require(script.Server)
red.State = require(script.State)
red.Store = require(script.Store)
red.Service = require(script.Service)
red.Controller = require(script.Controller)

export type SubscriptionId = string

export type ActionPayload = {
	[any]: any
}

export type Action = {
	uid: string?,
	method: string?,
	player: Player?,
	timeout: number?,
	type: string,
	payload: ActionPayload?,
	success: boolean?,
	err: string?
}

-- StateType
export type StateClass = {
	__index: StateClass;
	new: (initialState: { [any]: any }?) -> StateType;
	length: (self: StateType) -> number;
	get: (self: StateType, path: string) -> any;
	listen: (self: StateType, callback: (prevState: any, newState: any) -> nil) -> SubscriptionId;
	unlisten: (self: StateType, id: SubscriptionId) -> nil;
	pushUpdates: (self: StateType, prevState: any, newState: any) -> nil;
	push: (self: StateType, a: string, b: any) -> any;
	reset: (self: StateType) -> nil;
	set: (self: StateType, newState: any, value: any) -> nil;
	remove: (self: StateType, path: string) -> nil;
	destroy: (self: StateType) -> nil;
}

export type StateInstance = {
	_context: { [any]: any };
	_listeners: {
		[SubscriptionId]: (prevState: any, newState: any) -> nil
	};
	[any]: any;
}

export type StateType = typeof(setmetatable(
	{} :: StateInstance,
	{} :: StateClass
))

-- ServerType
export type ServerClass = {
	__index: ServerClass;
	new: () -> ServerType;
	bind: (self: ServerType, actionType: string, reducer: () -> any, private: boolean?) -> nil;
	unbind: (self: ServerType, id: string) -> nil;
	loadService: (self: ServerType, moduleInstance: ModuleScript) -> nil;
	loadServices: (self: ServerType, services: { ModuleScript }) -> nil;
	remotes: {
		Client: RemoteEvent,
		Server: RemoteEvent
	},
	sendError: (self: ServerType, err: string, userId: number?) -> nil,
	localCall: (self: ServerType, actionType: string, any) -> any,
	_call: (self: ServerType, action: Action, player: Player?) -> any,
	init: (self: ServerType) -> nil
}

export type ServerInstance = {
	_reducers: {
		[string]: (player: Player, payload: ActionPayload?) -> any
	},
	_privateReducers: {
		[string]: (player: Player, payload: ActionPayload?) -> any
	},
	_services: {
		[string]: any
	},
	[any]: any;
}

export type ServerType = typeof(setmetatable(
	{} :: ServerInstance,
	{} :: ServerClass
))

-- Service
export type ServerServiceConfig = {
	name: string,
	private: { string } | boolean?,
	[any]: any
}

export type ServerServiceClass = {
	__index: ServerServiceClass;
	new: (config: ServerServiceConfig) -> ServerService;
}

export type ServerServiceInstance = {
	_redService: boolean,
	_services: {
		[string]: any
	},
	[any]: any;
}

export type ServerService = typeof(setmetatable(
	{} :: ServerServiceInstance,
	{} :: ServerServiceClass
))

-- Controller
export type ControllerConfig = {
	name: string;
	[any]: any;
}

export type ControllerClass = {
	__index: ControllerClass;
	new: (config: ControllerConfig) -> ControllerType;
	destroy: (self: ControllerType) -> nil;
	addModules: (_controllers: Instance | { ModuleScript }, suffix: string?) -> nil;
	start: () -> nil;
	get: (name: string) -> ControllerType;
	init: (self: ControllerType) -> nil?;
	ready: (self: ControllerType) -> nil?;
	subscribe: (self: ControllerType, action: Action) -> nil;
	stepped: (self: ControllerType, callback: (deltaTime: number) -> nil) -> nil;
}

export type ControllerInstance = {
	name: string;
	controllerId: string;
	redController: boolean;
	[any]: any;
}

export type ControllerType = typeof(setmetatable(
	{} :: ControllerInstance,
	{} :: ControllerClass
))

return red
