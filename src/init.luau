--!strict

local Types = require(script.Types)
local redUtil = require(script.redUtil)

local red = {}

red.remotes = redUtil.getRemotes()

local Controller = require(script.Controller)
local Server = require(script.Server)
local State = require(script.State)
local Store = require(script.Store)

red.Server = Server
red.State = State
red.Store = Store
red.Controller = Controller

export type SubscriptionId = string

export type ActionPayload<T> = Types.ActionPayload<T>
export type Action<T> = Types.Action<T>

export type StateType = State.StateType

export type ServerType = Server.ServerType

export type ControllerConfig = Controller.ControllerConfig
export type ControllerType = Controller.ControllerType

export type StoreType = Store.StoreType

return red
