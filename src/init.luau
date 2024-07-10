--!strict

local Types = require(script.Types)
local redUtil = require(script.redUtil)

local red = {}

red.remotes = redUtil.getRemotes()

local Controller = require(script.Controller)
local Server = require(script.Server)
local Service = require(script.Service)
local State = require(script.State)
local Store = require(script.Store)

red.Server = Server
red.State = State
red.Store = Store
red.Service = Service
red.Controller = Controller

export type SubscriptionId = string

export type ActionPayload = Types.ActionPayload
export type Action = Types.Action

export type StateType = State.StateType

export type ServerType = Server.ServerType

export type ServiceClass = Service.ServiceClass
export type ServiceType = Service.ServiceType

export type ControllerConfig = Controller.ControllerConfig
export type ControllerType = Controller.ControllerType

export type StoreType = Store.StoreType

return red
