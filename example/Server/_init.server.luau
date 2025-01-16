local ReplicatedStorage = game:GetService("ReplicatedStorage")

local red = require(ReplicatedStorage.Packages.red)

local server: red.ServerType = red.Server.new()

server:useHandlers(script.Parent.Handlers)