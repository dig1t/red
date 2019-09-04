-- src/ReplicatedStorage/red/Root.lua

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')
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
		remotes = Instance.new('Folder', script.Parent)
		remotes.Name = 'Remotes'
		
		-- Communication to clients is done through this remote
		client = Instance.new('RemoteEvent', remotes)
		client.Name = 'Client'
		
		-- Communication to the server is done through this remote
		server = Instance.new('BindableEvent', remotes)
		server.Name = 'Server'
		
		-- Actions with callbacks are done through this remote
		local call = Instance.new('RemoteFunction', remotes)
		call.Name = 'Call'
	end
end

return _.extend(App, {
	Server = require(script.Server),
	State = require(script.State),
	Store = require(script.Store)
})