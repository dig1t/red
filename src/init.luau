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
red.Types = redTypes

export type ActionPayload = redTypes.ActionPayload
export type Action = redTypes.Action
export type State = redTypes.State
export type Server = redTypes.Server
export type ServerServiceConfig = redTypes.ServerServiceConfig
export type ServerService = redTypes.ServerService
export type SubscriptionId = redTypes.SubscriptionId
export type ControllerConfig = redTypes.ControllerConfig
export type ControllerType = redTypes.ControllerType

-- Alias
red.redTypes = redTypes

return red
