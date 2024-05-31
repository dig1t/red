--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Constants = require(script.Parent.Constants)

local Util = {}

function Util.getRemotes()
	local remotes = RunService:IsClient() and ReplicatedStorage:WaitForChild(Constants.REMOTE_FOLDER_NAME)
		or ReplicatedStorage:FindFirstChild(Constants.REMOTE_FOLDER_NAME)

	if not remotes then
		-- Container for remotes
		remotes = Instance.new("Folder")
		remotes.Name = Constants.REMOTE_FOLDER_NAME

		-- store:dispatch() calls from client to server and server to client
		local client: RemoteEvent = Instance.new("RemoteEvent")
		client.Name = "Client"
		client.Parent = remotes

		-- store:dispatch() calls from server to server
		local server: BindableEvent = Instance.new("BindableEvent")
		server.Name = "Server"
		server.Parent = remotes

		remotes.Parent = ReplicatedStorage
	end

	return remotes
end

return Util
