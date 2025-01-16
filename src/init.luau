--!strict

local Types = require(script.Types)
local redUtil = require(script.redUtil)

local red = {}

red.remotes = redUtil.getRemotes()

local State = require(script.State)
local Store = require(script.Store)

red.State = State
red.Store = Store

export type SubscriptionId = string

export type ActionPayload<T> = Types.ActionPayload<T>
export type Action<T> = Types.Action<T>

export type StateType = State.StateType

return red
