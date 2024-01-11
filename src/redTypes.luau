--!strict

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

-- State
export type StateClass = {
	__index: StateClass;
	new: (initialState: { [any]: any }?) -> State;
	length: (self: State) -> number;
	get: (self: State, path: string) -> any;
	listen: (self: State, callback: (prevState: any, newState: any) -> nil) -> SubscriptionId;
	unlisten: (self: State, id: SubscriptionId) -> nil;
	pushUpdates: (self: State, prevState: any, newState: any) -> nil;
	push: (self: State, a: string, b: any) -> any;
	reset: (self: State) -> nil;
	set: (self: State, newState: any, value: any) -> nil;
	remove: (self: State, path: string) -> nil;
	destroy: (self: State) -> nil;
}

export type StateInstance = {
	_context: { [any]: any };
	_listeners: {
		[SubscriptionId]: (prevState: any, newState: any) -> nil
	};
	[any]: any;
}

export type State = typeof(setmetatable(
	{} :: StateInstance,
	{} :: StateClass
))

-- Server
export type ServerClass = {
	__index: ServerClass;
	new: () -> Server;
	bind: (self: Server, actionType: string, reducer: () -> any, private: boolean?) -> nil;
	unbind: (self: Server, id: string) -> nil;
	loadService: (self: Server, moduleInstance: ModuleScript) -> nil;
	loadServices: (self: Server, services: { ModuleScript }) -> nil;
	remotes: {
		Client: RemoteEvent,
		Server: RemoteEvent
	},
	sendError: (self: Server, err: string, userId: number?) -> nil,
	localCall: (self: Server, actionType: string, any) -> any,
	_call: (self: Server, action: Action, player: Player?) -> any,
	init: (self: Server) -> nil
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

export type Server = typeof(setmetatable(
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

return {}
