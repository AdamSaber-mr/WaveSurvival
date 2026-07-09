-- ZombieAI: spawnt zombies op de markers en bestuurt ze.
-- Gedrag: zoek de dichtstbijzijnde levende speler → loop ernaartoe → mep (met cooldown).
-- Testmodus: elke golf heeft Config.Spawning.TestCount zombies; echte rondes komen in fase 5.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local ZombieFactory = require(script.Parent:WaitForChild("ZombieFactory"))

-- nette opbergmap in de wereld voor alle actieve zombies
local zombiesFolder = Instance.new("Folder")
zombiesFolder.Name = "Zombies"
zombiesFolder.Parent = workspace

local function getSpawnMarkers()
	local map = workspace:WaitForChild("Map")
	local spawns = map:WaitForChild("ZombieSpawns")
	local markers = {}
	for _, zoneFolder in ipairs(spawns:GetChildren()) do
		-- later filteren we hier op ontgrendelde zones; nu is alleen SpawnPlaza open
		for _, marker in ipairs(zoneFolder:GetChildren()) do
			table.insert(markers, marker)
		end
	end
	return markers
end

local function nearestAlivePlayer(fromPosition)
	local best, bestDistance = nil, math.huge
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and rootPart and humanoid.Health > 0 then
			local distance = (rootPart.Position - fromPosition).Magnitude
			if distance < bestDistance then
				best, bestDistance = rootPart, distance
			end
		end
	end
	return best, bestDistance
end

-- het "brein" van één zombie; draait in zijn eigen taak tot hij sterft
local function runZombie(model)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local rootPart = model.PrimaryPart
	local zombieConfig = Config.Zombie

	local lastAttackTime = 0
	local lastPosition = rootPart.Position
	local stuckTime = 0

	humanoid.Died:Connect(function()
		task.delay(zombieConfig.DespawnDelay, function()
			model:Destroy()
		end)
	end)

	while model.Parent and humanoid.Health > 0 do
		local target, distance = nearestAlivePlayer(rootPart.Position)
		if target then
			humanoid:MoveTo(target.Position)

			-- mep als we dichtbij genoeg zijn en de cooldown voorbij is
			if distance <= zombieConfig.AttackRange and os.clock() - lastAttackTime >= zombieConfig.AttackCooldown then
				lastAttackTime = os.clock()
				local targetHumanoid = target.Parent and target.Parent:FindFirstChildOfClass("Humanoid")
				if targetHumanoid then
					targetHumanoid:TakeDamage(zombieConfig.Damage)
				end
			end

			-- vastzit-detectie: amper bewogen terwijl het doel ver weg is → spring (bijv. over een toonbank)
			if (rootPart.Position - lastPosition).Magnitude < 0.5 and distance > 5 then
				stuckTime += 0.25
				if stuckTime >= 1 then
					humanoid.Jump = true
					stuckTime = 0
				end
			else
				stuckTime = 0
			end
			lastPosition = rootPart.Position
		end
		task.wait(0.25)
	end
end

local function spawnZombie(marker)
	local zombie = ZombieFactory.create()
	zombie.Parent = zombiesFolder
	zombie:PivotTo(CFrame.new(marker.Position + Vector3.new(0, 2, 0)))
	task.spawn(runZombie, zombie)
end

local function aliveZombieCount()
	local count = 0
	for _, zombie in ipairs(zombiesFolder:GetChildren()) do
		local humanoid = zombie:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			count += 1
		end
	end
	return count
end

-- test-golven: spawn een golf, wacht tot iedereen is uitgeschakeld, korte rust, opnieuw
task.spawn(function()
	local markers = getSpawnMarkers()
	print(("[Zombies] %d spawn-plekken gevonden"):format(#markers))
	task.wait(3) -- even ademruimte na het starten

	while true do
		print(("[Zombies] Nieuwe testgolf: %d zombies"):format(Config.Spawning.TestCount))
		for i = 1, Config.Spawning.TestCount do
			local marker = markers[(i - 1) % #markers + 1]
			spawnZombie(marker)
			task.wait(Config.Spawning.SpawnInterval)
		end

		repeat
			task.wait(1)
		until aliveZombieCount() == 0

		print(("[Zombies] Golf uitgeschakeld — volgende golf over %d seconden"):format(Config.Spawning.WaveRestDelay))
		task.wait(Config.Spawning.WaveRestDelay)
	end
end)
