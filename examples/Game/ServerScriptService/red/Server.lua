-- src/ServerScriptStorage/red/Server.lua

math.randomseed(os.time() * 1e6)

local ReplicatedStorage = game:GetService('ReplicatedStorage')
local ServerScriptService = game:GetService('ServerScriptService')
local ServerStorage = game:GetService('ServerStorage')
local DataStore = game:GetService('DataStoreService')
local HTTP = game:GetService('HttpService')
local App = require(ReplicatedStorage.red.Root)
local _ = require(ReplicatedStorage.red.Util)
local GameAnalytics = {} --require(ServerStorage.GameAnalytics)
local cfg = require(ServerScriptService.red.Config)

local server = App.Server.new()
local store = App.Store.new()

local debug, dev = cfg.debug, cfg.dev

local profileDB
local profileState = App.State.new()

if not dev and cfg.saveProfiles and cfg.profileStoreName then
	profileDB = DataStore:GetDataStore(cfg.profileStoreName)
end

function init()
	server:loadModules(script:GetChildren())
	
	if cfg.useGA then
		GameAnalytics:setEnabledInfoLog(cfg.ga.infoLog or cfg.dev)
		GameAnalytics:setEnabledVerboseLog(cfg.ga.verboseLog or cfg.dev)
		
		if cfg.ga.customDimensions01 then
			GameAnalytics:configureAvailableCustomDimensions01(cfg.ga.customDimensions01 or {})
		end
		
		if cfg.ga.customDimensions02 then
			GameAnalytics:configureAvailableCustomDimensions02(cfg.ga.customDimensions02 or {})
		end
		
		if cfg.ga.customDimensions03 then
			GameAnalytics:configureAvailableCustomDimensions03(cfg.ga.customDimensions03 or {})
		end
		
		if cfg.ga.currencies then
			GameAnalytics:configureAvailableResourceCurrencies(cfg.ga.currencies)
		end
		
		if cfg.ga.itemTypes then
			GameAnalytics:configureAvailableResourceItemTypes(cfg.ga.itemTypes)
		end
		
		GameAnalytics:configureBuild(cfg.build)
		GameAnalytics:initialize({
			gameKey = cfg.ga.gameKey,
			secretKey = cfg.ga.secret
		})
		
		-- Override default error handler
		function server.error(err, userId)
			error(err, 2)
			
			GameAnalytics:addErrorEvent(userId or 0, {
				severity = GameAnalytics.EGAErrorSeverity.error,
				message = 'Something went bad in some of the smelly code!'
			})
		end
	end
	
	server:init()
end

--[[
	@desc teleports a player
	@param object player - player object
	@param object location - teleport point
]]--
server:bind('PLAYER_TELEPORT', function(player, payload)
	if _.isAlive(player) then
		player.Character.PrimaryPart.CFrame = payload.location
	end
end)

------------------------------
-- players
--[[
	@desc returns all players not spectating
	@param boolean flag - return list for players playing a game (optional)
]]--
server:bind('PLAYERS_GET', function(payload)
	local res = {}
	
	for id, profile in pairs(profileState:get()) do
		if not profile.spectating and (
			(payload.flag == true and profile.playing) or not payload.flag
		) then
			res[#res + 1] = profile.entity
		end
	end
	
	return res
end)

--[[
	@desc sets a stat for all players
	@param string t - name of the table
	@param string key - name of the table's item
	@param string value - value to set
	@param boolean playing - run if users are playing a game or not (optional)
]]--
server:bind('PLAYERS_SET', function(payload)
	local players = server:localCall('PLAYERS_GET', {
		flag = payload.playing
	})
	
	for k, player in pairs(players) do
		server:localCall('PROFILE_SET', player, {
			tbl = payload.tbl,
			key = payload.key,
			value = payload.value
		})
	end
end)

------------------------------
-- profile

--[[
	@desc gets a user's profile
	@param object player - player
]]--
server:bind('PROFILE', function(player, payload)
	for id, profile in pairs(profileState:get()) do
		if player.userId == id then
			return profile
		end
	end
end)

--[[
	@desc gets a table or an item in a table from a user's profile
	@param object player - player
	@param string tbl - table name
	@param string key - key name
]]--
server:bind('PROFILE_GET', function(player, payload)
	local profile = server:localCall('PROFILE', player)
	local res
	
	if profile[payload.tbl] and profile[payload.tbl][payload.key] then
		res = profile[payload.tbl][payload.key]
	elseif profile[payload.tbl] then
		res = profile[payload.tbl]
	end
	
	return {
		type = 'PROFILE_GET' .. '_' .. string.upper((payload.tbl and payload.key) and payload.tbl .. '_' .. payload.key or payload.tbl),
		payload = res
	}
end)

--[[
	@desc updates a user's leaderstats and dispatches PROFILE_UPDATE to the user
	@param object player - player
]]--
server:bind('PROFILE_UPDATE', function(player, payload)
	if not player then return end
	
	local profile = server:localCall('PROFILE', player)
	
	profile.updatedKey = payload and payload.updatedKey
	
	if server.modules.level and profile.updatedKey == 'statistics_xp' then
		local levelOverview = server:localCall('LEVEL_OVERVIEW', player)
		
		profile.statistics.level = levelOverview.payload.level
		
		store:dispatch(player, levelOverview)
	end
	
	if cfg.leaderboard_stats and player:FindFirstChild('leaderstats') then
		for k, score in pairs(player.leaderstats:GetChildren()) do
			for stat, value in pairs(profile.statistics) do
				if string.lower(score.Name) == string.lower(stat) then
					score.Value = value
				end
			end
		end
	end
	
	store:dispatch(player, {
		type = 'PROFILE_UPDATE',
		payload = profile,
	})
end)

--[[
	@desc set a stat
	@param object player - player
	@param string tbl - name of the table
	@param string key - name of the table's item
	@param string value - value to set
]]--
server:bind('PROFILE_SET', function(player, payload)
	if not player then return end
	
	local tbl, key, value = payload.tbl, payload.key, payload.value
	
	local success = pcall(function()
		profileState:set(function(state)
			if state[player.userId] and key then
				if not tbl and state[player.userId][key] ~= nil then
					state[player.userId][key] = value
				elseif tbl and state[player.userId][tbl] ~= nil and state[player.userId][tbl][key] ~= nil then
					state[player.userId][tbl][key] = value
				else
					error('Could not set: ' .. key .. ' to: ' .. value)
				end
			end
			
			return state
		end)
	end)
	
	if success then
		server:localCall('PROFILE_UPDATE', player, {
			updatedKey = (tbl and key) and tbl .. '_' .. key or key
		})
	end
end)

--[[
	@desc add a stat
	@param object player - player
	@param string tbl - name of the table
	@param string key - name of the table's item
	@param int value - number to add
]]--
server:bind('PROFILE_ADD', function(player, payload)
	if not player then return end
	
	local value = server:localCall('PROFILE_GET', player, {
		tbl = payload.tbl,
		key = payload.key
	}).payload
	
	server:localCall('PROFILE_SET', player, {
		tbl = payload.tbl,
		key = payload.key,
		value = payload.value + value
	})
end)

--[[
	@desc subtracts a stat
	@param object player - player
	@param string t - name of the table
	@param string key - name of the table's item
	@param int value - number to subtract
]]--
server:bind('PROFILE_SUBTRACT', function(player, payload)
	server:localCall('PROFILE_ADD', player, {
		tbl = payload.tbl,
		key = payload.key,
		value = -payload.value
	})
end)

--[[
	@desc save the user's profile to the game's roblox database
	@param object player - player
]]--
server:bind('PROFILE_SAVE', function(player)
	if profileDB then
		local profile = server:localCall('PROFILE', player)
		
		if not profile then return end
		
		-- track total play time
		if cfg.trackTime then
			profile.statistics.total_time = profile.statistics.total_time + (_.unix() - profile.session_start)
		end
		
		if not profile.dontSave then
			profile.entity = nil -- dont save the player object
			
			local success, res, tries = _.attempt(function()
				profileDB:UpdateAsync(player.userId, function(oldValue)
					local prevData = oldValue or { _id = 0 } -- Simulate id if user does not have a profile saved
					
					if profile._id == prevData._id then
						profile._id = _.randomString(8) -- set a new 
						
						return HTTP:JSONEncode(profile) -- Encode profile data as JSON
					end
				end)
			end, 3, 2) -- Attempt to save data 3 times every 2 seconds
			
			if success and tries ~= 0 then
				print('Server - Took ', tries, ' tries to save data for player: ', player.userId)
			end
			
			if not success then
				profile.dontSave = true
				print('Server - Could not save data for player: ', player.userId)
			end
			
			profile.entity = player
		end
	end
end)


game.Players.PlayerAdded:connect(function(player)
	if server:localCall('ADMIN_CHECK_IF_BANNED', player).payload then
		return server:localCall('ADMIN_KICK', player, 'You are banned from the game')
	end
	
	local isAdmin = server:localCall('ADMIN_CHECK', player).payload
	
	player.Chatted:connect(function(message)
		--[[if cfg.events.chatted then
			cfg.events.chatted(message)
		end]]
		
		if not isAdmin then return end
		
		server:localCall('ADMIN_SPOKE', player, {
			message = message
			--recipient = recipient
		})
	end)
	
	player.CharacterAdded:connect(function(character)
		local humanoid = character:WaitForChild('Humanoid')
		
		--[[if cfg.events.spawn then
			cfg.events.spawn(character)
		end
		
		if cfg.events.died then
			humanoid.Died:connect(function()
				cfg.events.died(player)
			end)
		end]]
		
		if cfg.spawns then
			local spawn = _.randomObj(cfg.spawns)
			
			if spawn and character:FindFirstChild('Head') then
				local offset = spawn:FindFirstChild('Offset')
				
				if not offset then
					offset = { X = 8, Z = 8 }
				else
					offset = offset.Value
				end
				
				local X = _.random(offset.X, -offset.X)
				local Z = _.random(offset.Z, -offset.Z)
				wait()
				character.Head.CFrame = spawn.CFrame * CFrame.new(X, 8, Z)
			end
		end
	end)
	
	-- profile setup
	local profile = cfg.defaultProfile(player)
	
	if server.modules.level then
		profile.statistics.xp = 0
		profile.statistics.level = 1 -- level starts at 1
	end
	
	if profileDB and player.userId > 0 then
		local success, res, tries = _.attempt(function()
			local fetch = profileDB:GetAsync(player.userId)
			
			if fetch then
				profile = HTTP:JSONDecode(fetch)
			end
		end, 3, 2) -- Attempt to get data 3 times every 2 seconds
		
		if success and tries ~= 0 then
			print('Server - Took ', tries, ' tries to get data for player: ', player.userId) -- LOG AMOUNT OF TRIES
		end
		
		if not success then
			profile.dontSave = true
			print('Server - Could not save data for player: ', player.userId) -- LOG INCIDENT
		end
	end
	
	profile.entity = player
	profile.userId = player.userId
	profile.username = player.Name
	profile.isAdmin = isAdmin
	
	if cfg.players.trackTime then
		profile.session_start = _.unix()
	end
	
	profileState:set(_.merge(profileState:get(), {
		[player.userId] = profile
	}))
	
	if cfg.leaderboard_stats then
		local statistics = _({ class = 'IntValue', Name = 'leaderstats' })
		
		for i, name in pairs(cfg.leaderboardStats) do
			local leaderstat = _({ class = 'IntValue', Name = name, Parent = statistics, Value = 0 })
			
			for stat, value in pairs(profile.statistics) do
				if string.lower(name[i]) == string.lower(stat) then
					leaderstat.Value = value
					break
				end
			end
		end
		
		statistics.Parent = player
	end
	
	if cfg.events.entered then
		cfg.events.entered(player)
	end
	
	if cfg.useGA then
		GameAnalytics:PlayerJoined(player)
	end
	
	if cfg.dev and cfg.debug then
		print(HTTP:JSONEncode(profile))
	end
	
	server:localCall('PROFILE_UPDATE', player)
	store:dispatch(true, { -- Tell all the clients that a player joined
		type = 'PLAYER_JOINED',
		payload = profile
	})
	
	coroutine.resume(coroutine.create(function()
		while player and wait(cfg.save_interval or 120) do
			server:localCall('PROFILE_SAVE', player)
		end
	end))
end)

game.Players.PlayerRemoving:connect(function(player)
	server:localCall('PROFILE_SAVE', player)
	
	local profiles = profileState:get()
	
	for i, profile in pairs(profiles) do
		if profile.userId == player.userId then
			table.remove(profileState, i)
		end
	end
	
	profileState:set(profiles)
	
	--[[if cfg.events.left then
		cfg.events.left(player)
	end]]
	
	store:dispatch(true, { -- Tell all the clients that a player left
		type = 'PLAYER_LEFT',
		payload = player.userId
	})
end)

init()