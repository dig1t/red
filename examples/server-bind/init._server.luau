--!nocheck

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Util = require(ReplicatedStorage.Packages.Util)
local red = require(ReplicatedStorage.Packages.red)

red.bind("PLAYER_TELEPORT", function(player, payload)
	if Util.isAlive(player) then
		task.wait()

		player.Character.PrimaryPart.CFrame = payload.location
	end
end)

local function playerAdded(player)
	player.CharacterAdded:Connect(function(character)
		if not character.Parent then
			character.AncestryChanged:Wait()

			if not character.Parent then
				return
			end
		end

		character:WaitForChild("Humanoid")

		red.dispatch(player, {
			type = "PLAYER_TELEPORT",
			payload = {
				location = CFrame.new(Util.random(-100, 100), 40, Util.random(-100, 100)),
			},
		})
	end)
end

-- Add players that joined before the connection was created
for _, player in pairs(Players:GetPlayers()) do
	playerAdded(player)
end

Players.PlayerAdded:Connect(playerAdded)
