--!strict

export type SubscriptionId = string

export type ActionPayload<T> = T

export type Action<T> = {
	uid: string?,
	method: string?,
	player: Player?,
	timeout: number?,
	type: string,
	payload: ActionPayload<T>,
	success: boolean?,
	err: string?,
}

return {}
