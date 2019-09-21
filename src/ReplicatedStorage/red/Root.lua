-- src/ReplicatedStorage/red/Root.lua

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local _ = require(ReplicatedStorage.red.Util)

local App = {}

App.__index = App

-- Error handler
function App.error(err)
	print(err)
end

do
	App.remotes = script.Parent:FindFirstChild('Remotes')
	
	if not App.remotes then
		-- Container for remotes
		local remotes = Instance.new('Folder', script.Parent)
		remotes.Name = 'Remotes'
		
		-- store:dispatch() calls from client to server and server to client
		local client = Instance.new('RemoteEvent', remotes)
		client.Name = 'Client'
		
		-- store:dispatch() calls from server to server
		local server = Instance.new('BindableEvent', remotes)
		server.Name = 'Server'
		
		-- store:get() calls from client to server
		local clientCall = Instance.new('RemoteFunction', remotes)
		clientCall.Name = 'ClientCall'
		
		-- store:get() from server to server
		local serverCall = Instance.new('BindableFunction', remotes)
		serverCall.Name = 'ServerCall'
	end
end

return _.extend(App, {
	Server = require(script.Server),
	State = require(script.State),
	Store = require(script.Store)
})