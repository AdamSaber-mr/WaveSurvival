-- ZombieService: het zombie-brein als herbruikbare module.
-- De RoundManager (wedstrijdleider) bestelt hier zombies; deze module regelt
-- het spawnen, achtervolgen en aanvallen. Was eerst ZombieAI.server.luau.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local ZombieFactory = require(script.Parent:WaitForChild("ZombieFactory"))

local ZombieService = {}

-- nette opbergmap in de wereld voor alle actieve zombies
local zombiesFolder = Instance.new("Folder")
zombiesFolder.Name = "Zombies"
zombiesFolder.Parent = workspace

function ZombieService.getSpawnMarkers()
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

-- spawn één zombie op een marker, optioneel met ronde-stats (Health/WalkSpeed)
function ZombieService.spawn(marker, statOverrides)
	local zombie = ZombieFactory.create(statOverrides)
	zombie.Parent = zombiesFolder
	zombie:PivotTo(CFrame.new(marker.Position + Vector3.new(0, 2, 0)))
	task.spawn(runZombie, zombie)
	return zombie
end

function ZombieService.aliveCount()
	local count = 0
	for _, zombie in ipairs(zombiesFolder:GetChildren()) do
		local humanoid = zombie:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			count += 1
		end
	end
	return count
end

return ZombieService
