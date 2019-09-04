local ReplicatedStorage = game:GetService('ReplicatedStorage')
local App = require(ReplicatedStorage.red.Root)
local _ = require(game.ReplicatedStorage.red.Util)

local ui = _.getAncestor(script, 'UI')
local store = App.Store.new()

local levelBar = ui.Navigation.Screen.levelBar
local level, lastAction

store:subscribe(function(action)
	--[[if action.type == _.PROFILE_GET then
		level = action.payload.statistics.level
	end]]
	
	if action.type == 'LEVEL_UPDATE' then
		if level and action.payload.level > level then
			ui.Sounds.level_up:Play()
		end
		
		level = action.payload.level
		levelBar.Visible = true
		
		levelBar.CurrentLevel.Circle.Value.Text = _.formatInt(level)
		levelBar.NextLevel.Circle.Value.Text = _.formatInt(level + 1)
		levelBar.Progress.Static.Size = UDim2.new(action.payload.levelProgress, 0, 1, 0)
		levelBar.Progress.xp.Text = _.formatInt(action.payload.xp)..' / '.._.formatInt(action.payload.xpRequired)
		
		wait(.2)
		
		levelBar.Progress.Bar:TweenSize(UDim2.new(action.payload.levelProgress, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Linear, .5)
		
		local timestamp = _.unix()
		lastAction = timestamp
		
		wait(3)
		
		if lastAction == timestamp then
			levelBar.Visible = false
		end
	end
end)