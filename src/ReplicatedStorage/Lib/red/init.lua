local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

local Util = require(ReplicatedStorage.Lib.Util)

local red = {}

red.__index = red

-- Error handler
function red.error(err)
	print(err)
end

red.remotes = RunService:IsClient() and ReplicatedStorage:WaitForChild('red') or ReplicatedStorage:FindFirstChild('red')

if not red.remotes then
	-- Container for remotes
	red.remotes = Instance.new('Folder')
	red.remotes.Name = 'red'
	
	-- store:dispatch() calls from client to server and server to client
	local client = Instance.new('RemoteEvent')
	client.Name = 'Client'
	client.Parent = red.remotes
	
	-- store:dispatch() calls from server to server
	local server = Instance.new('BindableEvent')
	server.Name = 'Server'
	server.Parent = red.remotes
	
	red.remotes.Parent = ReplicatedStorage
end

return Util.extend(red, {
	Server = require(script.Server),
	State = require(script.State),
	Store = require(script.Store)
})