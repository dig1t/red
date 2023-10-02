local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local dLib = require(script.dLib)
local Util = dLib.import("Util")

local Constants = require(script.Constants)

local red = {}
red.__index = red

-- Error handler
function red.error(err)
	print(err)
end

red.remotes = RunService:IsClient() and
	ReplicatedStorage:WaitForChild(Constants.REMOTE_FOLDER_NAME) or
	ReplicatedStorage:FindFirstChild(Constants.REMOTE_FOLDER_NAME)

if not red.remotes then
	-- Container for remotes
	red.remotes = Instance.new("Folder")
	red.remotes.Name = Constants.REMOTE_FOLDER_NAME
	
	-- store:dispatch() calls from client to server and server to client
	local client = Instance.new("RemoteEvent")
	client.Name = "Client"
	client.Parent = red.remotes
	
	-- store:dispatch() calls from server to server
	local server = Instance.new("BindableEvent")
	server.Name = "Server"
	server.Parent = red.remotes
	
	red.remotes.Parent = ReplicatedStorage
end

return Util.extend(red, {
	Server = require(script.Server),
	State = require(script.State),
	Store = require(script.Store)
})