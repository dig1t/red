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
	new: (initialState: { [any]: any }?) -> StateType;
	length: (self: StateType) -> number;
	get: (self: StateType, path: string) -> any;
	listen: (self: StateType, callback: (prevState: any, newState: any) -> nil) -> SubscriptionId?;
	unlisten: (self: StateType, id: SubscriptionId) -> nil;
	pushUpdates: (self: StateType, prevState: any, newState: any) -> nil;
	push: (self: StateType, a: string, b: any) -> any;
	reset: (self: StateType) -> nil;
	set: (self: StateType, newState: any, value: any) -> nil;
	remove: (self: StateType, path: string) -> nil;
	destroy: (self: StateType) -> nil;

	StateType: StateType;
}

export type StateInstance = {
	_context: { [any]: any }?;
	_listeners: {
		[SubscriptionId]: (prevState: any, newState: any) -> nil
	}?;
	[any]: any;
}

export type StateType = typeof(setmetatable(
	{} :: StateInstance,
	{} :: StateClass
))

-- Server
export type ServerClass = {
	__index: ServerClass;
	new: () -> ServerType;
	bind: (self: ServerType, actionType: string, reducer: () -> any, private: boolean?) -> nil;
	unbind: (self: ServerType, id: string) -> nil;
	loadService: (self: ServerType, moduleInstance: ModuleScript) -> nil;
	loadServices: (self: ServerType, services: { ModuleScript }) -> nil;
	remotes: {
		Client: RemoteEvent;
		Server: RemoteEvent;
	};
	sendError: (self: ServerType, err: string, userId: number?) -> nil;
	localCall: (self: ServerType, actionType: string, any) -> any;
	_call: (self: ServerType, action: Action, player: Player?) -> any;
	init: (self: ServerType) -> nil;

	ServerType: ServerType;
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

-- Store
export type StoreClass = {
	__index: StoreClass;
	new: () -> StoreType;
	dispatch: (self: StoreType, any) -> nil;
	get: (self: StoreType, action: Action) -> any;
	_callSubscribers: (self: StoreType, action: Action, safeCall: boolean?) -> nil;
	subscribe: (self: StoreType, callback: (action: Action) -> nil) -> SubscriptionId;
	unsubscribe: (self: StoreType, id: SubscriptionId) -> nil;

	StoreType: StoreType;
}

export type StoreInstance = {
	_connections: { [number]: RBXScriptConnection };
	_subscribers: { [SubscriptionId]: (action: Action) -> nil };
	[any]: any;
}

export type StoreType = typeof(setmetatable(
	{} :: StoreInstance,
	{} :: StoreClass
))

-- Service
export type ServiceConfig = {
	name: string,
	private: { string } | boolean?,
	[any]: any
}

export type ServiceClass = {
	__index: ServiceClass;
	new: (config: ServiceConfig) -> ServiceType;

	ServiceType: ServiceType;
}

export type ServiceInstance = {
	_redService: boolean,
	_services: {
		[string]: any
	},
	[any]: any;
}

export type ServiceType = typeof(setmetatable(
	{} :: ServiceInstance,
	{} :: ServiceClass
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

	ControllerType: ControllerType;
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
