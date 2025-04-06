--!strict

export type BindCallback = (Player, ActionPayload<any>) -> ()
export type Bind = (string, BindCallback) -> ()

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

export type Handler = (Bind) -> ()

return {}
