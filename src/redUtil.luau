--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Constants = require(script.Parent.Constants)

local Util = {}

function Util.getRemotes(): { Client: RemoteEvent, Server: BindableEvent }
	local remotes = RunService:IsClient()
			and ReplicatedStorage:WaitForChild(Constants.REMOTE_FOLDER_NAME)
		or ReplicatedStorage:FindFirstChild(Constants.REMOTE_FOLDER_NAME)

	if remotes then
		return {
			Client = remotes:WaitForChild("Client", 60) :: RemoteEvent,
			Server = remotes:WaitForChild("Server", 60) :: BindableEvent,
		}
	end

	-- Container for remotes
	local newRemotes = Instance.new("Folder")
	newRemotes.Name = Constants.REMOTE_FOLDER_NAME

	-- store:dispatch() calls from client to server and server to client
	local client: RemoteEvent = Instance.new("RemoteEvent")
	client.Name = "Client"
	client.Parent = newRemotes

	-- store:dispatch() calls from server to server
	local server: BindableEvent = Instance.new("BindableEvent")
	server.Name = "Server"
	server.Parent = newRemotes

	newRemotes.Parent = ReplicatedStorage

	return {
		Client = client,
		Server = server,
	}
end

return Util
