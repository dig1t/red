--!strict

local redTypes = require(script.redTypes)
local redUtil = require(script.redUtil)

local red = {}

red.remotes = redUtil.getRemotes()

red.Server = require(script.Server)
red.State = require(script.State)
red.Store = require(script.Store)
red.Service = require(script.Service)
red.Controller = require(script.Controller)

export type SubscriptionId = string

export type ActionPayload = redTypes.ActionPayload
export type Action = redTypes.Action

export type StateClass = redTypes.StateClass
export type StateInstance = redTypes.StateInstance
export type StateType = redTypes.State

export type ServerClass = redTypes.ServerClass
export type ServerInstance = redTypes.ServerInstance
export type ServerType = redTypes.Server

export type ServerServiceConfig = redTypes.ServerServiceConfig
export type ServerServiceClass = redTypes.ServerServiceClass
export type ServerServiceInstance = redTypes.ServerServiceInstance
export type ServerService = redTypes.ServerService

export type ControllerConfig = redTypes.ControllerConfig
export type ControllerClass = redTypes.ControllerClass
export type ControllerInstance = redTypes.ControllerInstance
export type ControllerType = redTypes.ControllerType

return red
