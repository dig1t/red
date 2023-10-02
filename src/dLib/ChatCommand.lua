-- ChatCommand API
--- boolean ignoreIfDead - Only passes alive players through targets table
--- boolean noTargets - Doesn't insert targets during the command processing
--- number minimumLevel (default: moderator) - Minimum user level required to use command
--- boolean adminsExempt - Any admins included in the command call will not be inserted into the targets table

local dLib = require(script.Parent)
local Util = dLib.import("Util")

local ChatCommand, methods = {}, {}
methods.__index = methods

local PREFIX = "/"
local PREFIX_LENGTH = #PREFIX

local _commands = {}

ChatCommand.minimumLevel = Util.userLevel.normal

-- Loads all commands from given table or ModuleScript
function ChatCommand.use(source)
	local res = source
	
	if typeof(source) == "Instance" then
		local success, err = pcall(function()
			res = require(source)
		end)
		
		if not success then
			error(err)
		end
	end
	
	for name, command in pairs(res) do
		assert(command[1], "Missing function for command: " .. name)
	end
	
	Util.extend(_commands, res)
end

function ChatCommand.insert(name, command)
	assert(name, "Missing command name")
	assert(command[1], "Missing function for command: " .. name)
	
	_commands[name] = command
end

function ChatCommand.getPlayers(player, text, ignoreIfDead)
	local targets = {}
	
	if text == "me" or not text then
		return { player }
	elseif text == "all" then
		targets = game.Players:GetPlayers()
	elseif text == "others" then
		targets = game.Players:GetPlayers()
		
		for i, v in pairs(targets) do
			if v == player then
				table.remove(targets, i)
			end
		end
	else
		for _, target in pairs(game.Players:GetPlayers()) do
			if string.lower(target.Name):match(string.lower(text)) then
				targets = { target }
				break
			end
		end
	end
	
	if ignoreIfDead then
		for i, target in pairs(targets) do
			if not Util.isAlive(target) then
				table.remove(targets, i)
			end
		end
	end
	
	return targets
end

function ChatCommand.test(text)
	return text:sub(0, PREFIX_LENGTH) == "/"
end

function ChatCommand.exists(name)
	return _commands[name] ~= nil
end

function methods:process()
	if not self.valid then
		return
	end
	
	local command = _commands[self.commandName]
	local parameters = { [1] = self.player }
	
	if command.minimumLevel and self.userLevel < (command.minimumLevel or ChatCommand.minimumLevel) then
		-- Player has insufficient privileges to execute commmand
		return
	end
	
	if not command.noTargets then
		local targets
		
		if self.sections[1] then
			targets = ChatCommand.getPlayers(self.player, self.sections[1], command.ignoreIfDead)
			Util.tableRemove(self.sections, 1)
		elseif command.ignoreIfDead ~= true and Util.isAlive(self.player) == false or true then
			targets = { self.player }
		end
		
		parameters[#parameters + 1] = targets or {}
		
		if command.adminsExempt then
			for i, target in pairs(targets) do
				if Util.getUserLevel(target) >= Util.userLevel.superuser then
					table.remove(targets, i)
				end
			end
		end
	end
	
	for _, v in ipairs(self.sections) do
		parameters[#parameters + 1] = v
	end
	
	command[1](unpack(parameters))
end

function ChatCommand.new(data)
	assert(data.player, 'ChatCommand.new - Player missing')
	assert(typeof(data.text) == "string", 'ChatCommand.new - Text argument must be a string')
	
	local self = setmetatable({}, methods)
	
	-- Make sure the string starts with the defined prefix
	if ChatCommand.test(data.text) then
		self.test = string.lower(data.text)
		self.sections = data.text:sub(PREFIX_LENGTH + 1):split(" ")
		self.player = data.player
		self.userLevel = data.userLevel or Util.userLevel.normal
		
		if #self.sections > 0 and ChatCommand.exists(string.lower(self.sections[1])) then
			self.commandName = self.sections[1]
			self.valid = true
			
			table.remove(self.sections, 1)
		end
	end
	
	return self
end

return ChatCommand