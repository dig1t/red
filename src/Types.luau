--!strict

export type SubscriptionId = string

export type ActionPayload<T> = T

export type Action = {
	uid: string?,
	method: string?,
	player: Player?,
	timeout: number?,
	type: string,
	payload: ActionPayload<any>,
	success: boolean?,
	err: string?,
}

return {}
