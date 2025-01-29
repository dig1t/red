local ReplicatedStorage = game:GetService("ReplicatedStorage")

local red = require(ReplicatedStorage.Packages.red)

local Loader = require(script.Parent.Handlers.Loader)
local PingPong = require(script.Parent.Handlers.PingPong)

red.useHandlers({
	Loader,
	PingPong,
})

-- Alternatively you can use red.useHandlers(script.Parent.Handlers)
-- This will automatically bind all handlers in the Handlers folder
