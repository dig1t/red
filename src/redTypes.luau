--!strict

export type Action = {
	uid: string?,
	method: string?,
	player: Player?,
	timeout: number?,
	type: string,
	payload: table?,
	success: boolean?,
	err: string?
}

export type State = {
	context: table,
	listeners: {
		[SubscriptionId]: (prevState: any, newState: any) -> nil
	}
}

export type Server = {
	_reducers: {
		[string]: (player: Player, payload: table?) -> any
	},
	_privateReducers: {
		[string]: (player: Player, payload: table?) -> any
	},
	remotes: {
		Client: RemoteEvent,
		Server: RemoteEvent
	},
	sendError: (self: Server, err: string, userId: number?) -> nil,
	localCall: (self: Server, actionType: string, any) -> any,
	call: (self: Server, action: Action, player: Player?) -> any,
	init: (self: Server) -> nil
}

export type ServerServiceConfig = {
	name: string,
	private: { string } | boolean?,
	[any]: (any) -> any
}

export type ServerService = {
	[any]: any
}

export type SubscriptionId = string

export type ControllerConfig = {
	name: string;
}

export type ControllerType = {
	name: string;
	init: (self: ControllerType) -> nil;
	redSubscribe: (self: ControllerType, callback: (action: any) -> nil) -> nil;
	redController: boolean;
	-- stepped: (self: ControllerType, callback: (deltaTime: number) -> nil) -> nil;
}

return {}