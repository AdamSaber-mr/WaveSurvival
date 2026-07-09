-- RoundManager: de wedstrijdleider — het kloppende hart van de game-loop.
-- Elke ronde: meer zombies, met meer health en meer snelheid (formules in Config.Rounds).
-- Het rondenummer wordt als "sticker" (Attribute) op ReplicatedStorage geplakt,
-- zodat elke tv (HUD) er direct naar kan kijken.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local ZombieService = require(script.Parent:WaitForChild("ZombieService"))

local roundsConfig = Config.Rounds

local function statsForRound(round)
	return {
		Health = Config.Zombie.Health + (round - 1) * roundsConfig.HealthPerRound,
		WalkSpeed = math.min(Config.Zombie.WalkSpeed + (round - 1) * roundsConfig.SpeedPerRound, roundsConfig.MaxSpeed),
	}
end

local function countForRound(round)
	return roundsConfig.BaseCount + (round - 1) * roundsConfig.CountPerRound
end

task.spawn(function()
	local markers = ZombieService.getSpawnMarkers()
	print(("[Rondes] %d spawn-plekken gevonden"):format(#markers))

	ReplicatedStorage:SetAttribute("Round", 0)
	task.wait(roundsConfig.FirstRoundDelay)

	local round = 0
	while true do
		round += 1
		ReplicatedStorage:SetAttribute("Round", round)

		local count = countForRound(round)
		local stats = statsForRound(round)
		print(("[Rondes] Ronde %d: %d zombies (health %d, snelheid %.1f)"):format(round, count, stats.Health, stats.WalkSpeed))

		for i = 1, count do
			local marker = markers[(i - 1) % #markers + 1]
			ZombieService.spawn(marker, stats)
			task.wait(roundsConfig.SpawnInterval)
		end

		-- wacht tot de hele ronde is uitgeschakeld
		repeat
			task.wait(1)
		until ZombieService.aliveCount() == 0

		print(("[Rondes] Ronde %d uitgeschakeld! Volgende ronde over %d seconden"):format(round, roundsConfig.RestBetweenRounds))
		task.wait(roundsConfig.RestBetweenRounds)
	end
end)
