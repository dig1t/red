--!strict

local Types = require(script.Types)
local redUtil = require(script.redUtil)

local red = {}

red.remotes = redUtil.getRemotes()

red.Server = require(script.Server)
red.State = require(script.State)
red.Store = require(script.Store)
red.Service = require(script.Service)
red.Controller = require(script.Controller)

export type SubscriptionId = string

export type ActionPayload = Types.ActionPayload
export type Action = Types.Action

export type StateClass = Types.StateClass
export type StateInstance = Types.StateInstance
export type StateType = Types.State

export type ServerClass = Types.ServerClass
export type ServerInstance = Types.ServerInstance
export type ServerType = Types.Server

export type ServerServiceConfig = Types.ServerServiceConfig
export type ServerServiceClass = Types.ServerServiceClass
export type ServerServiceInstance = Types.ServerServiceInstance
export type ServerService = Types.ServerService

export type ControllerConfig = Types.ControllerConfig
export type ControllerClass = Types.ControllerClass
export type ControllerInstance = Types.ControllerInstance
export type ControllerType = Types.ControllerType

return red
