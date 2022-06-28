local TweenService = game:GetService('TweenService')
local RunService = game:GetService('RunService')

local dLib = require(script.Parent)
local Util = dLib.import('Util')

local DEFAULT_ANIMATION_CONFIG = {
	
}

local Animation = {}

function Animation.prepareAnimatedModel(model)
	if not model.PrimaryPart then
		return
	end
	
	model.PrimaryPart.Anchored = true
	
	for _, part in pairs(model:GetDescendants()) do
		if part ~= model.PrimaryPart and part:IsA('BasePart') then
			Util.weld(part, model.PrimaryPart)
			part.Anchored = false
		end
	end
end

function Animation.setDefaultConfig(config)
	assert(config and typeof(config) == 'table', 'Table must be passed to set the default animation config')
	
	DEFAULT_ANIMATION_CONFIG = config
end

function Animation.animate(config)
	assert(config and typeof(config) == 'table', 'Missing animation configuration')
	
	-- Support UIKit Elements
	config.instance = config.instance and (
		typeof(config.instance) == 'table' and config.instance.ui and config.instance.context
	) or (
		typeof(config.instance) == 'Instance' and config.instance
	)
	
	assert(config.instance, 'Missing instance to animate')
	assert(config.stop, 'Missing animation goal')
	assert(config.tweenInfo, 'Missing TweenInfo')
	
	-- Place default values
	for k, v in pairs(DEFAULT_ANIMATION_CONFIG) do
		if config[k] == nil then
			config[k] = v
		end
	end
	
	if config.start then
		for property, value in pairs(config.start) do
			config.instance[property] = value
		end
	end
	
	local TweenBuild = TweenService:Create(
		config.instance,
		config.tweenInfo,
		config.stop
	)
	
	TweenBuild:Play()
	
	if config.frameCallback then
		while TweenBuild.PlaybackState == Enum.PlaybackState.Playing do
			config.frameCallback()
			RunService.Stepped:Wait()
		end
	end
	
	if config.async then
		TweenBuild.Completed:Wait()
	end
	
	if config.stopCallback then
		config.stopCallback()
	end
end

return Animation