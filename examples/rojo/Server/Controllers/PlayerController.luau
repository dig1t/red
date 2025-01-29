local PlayerController = {}

function PlayerController.kill(player: Player): boolean?
	local character = player.Character :: Model?
	local humanoid = character
		and character:FindFirstChildOfClass("Humanoid") :: Humanoid?

	if humanoid then
		humanoid.Health = 0

		print(player.Name .. " was killed!")

		return true
	end

	return false
end

function PlayerController.damage(player: Player, amount: number)
	local character = player.Character :: Model?
	local humanoid = character
		and character:FindFirstChildOfClass("Humanoid") :: Humanoid?

	if humanoid then
		humanoid.Health -= amount
		print(`{player.Name} took {amount} damage!`)
	end
end

return PlayerController
