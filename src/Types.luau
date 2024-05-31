--!strict

export type SubscriptionId = string

export type ActionPayload = {
	[any]: any,
}

export type Action = {
	uid: string?,
	method: string?,
	player: Player?,
	timeout: number?,
	type: string,
	payload: ActionPayload?,
	success: boolean?,
	err: string?,
}

return {}
