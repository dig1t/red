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
red.redTypes = redTypes

-- Alias
red.Types = redTypes

return red