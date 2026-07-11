-- ZombieService: het zombie-brein als herbruikbare module.
-- De RoundManager (wedstrijdleider) bestelt hier zombies; deze module regelt
-- het spawnen, achtervolgen en aanvallen. Was eerst ZombieAI.server.luau.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")

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
		-- alleen ontgrendelde zones: SpawnPlaza is altijd open, de rest pas na het kopen van de deur
		local unlocked = zoneFolder.Name == "SpawnPlaza" or map:GetAttribute("Unlocked_" .. zoneFolder.Name) == true
		if unlocked then
			for _, marker in ipairs(zoneFolder:GetChildren()) do
				table.insert(markers, marker)
			end
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

-- ===== ZOMBIE-ZINTUIGEN =====

-- kan de zombie de speler rechtstreeks zien? (geen muur ertussen)
local function hasLineOfSight(fromPosition, targetPart)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { zombiesFolder }
	local result = workspace:Raycast(fromPosition, targetPart.Position - fromPosition, params)
	if not result then
		return true -- niks ertussen
	end
	return result.Instance:IsDescendantOf(targetPart.Parent) -- we raakten de speler zelf
end

-- de "voelspriet": zit er vlak voor de zombie een obstakel (muurtje/toonbank)?
local function obstacleAhead(rootPart, moveDirection)
	local flat = Vector3.new(moveDirection.X, 0, moveDirection.Z)
	if flat.Magnitude < 0.1 then
		return false
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { zombiesFolder }
	-- op kniehoogte, 3 studs vooruit
	local result = workspace:Raycast(rootPart.Position + Vector3.new(0, -1, 0), flat.Unit * 3, params)
	if not result or not result.Instance.CanCollide then
		return false
	end
	-- spring niet tegen spelers/poppen aan, alleen tegen dingen
	local model = result.Instance:FindFirstAncestorOfClass("Model")
	if model and model:FindFirstChildOfClass("Humanoid") then
		return false
	end
	-- is het obstakel laag genoeg om overheen te springen? (check op ~6 studs hoogte:
	-- zit het dáár ook dicht, dan is het een hoge muur → niet springen, routeplanner lost het op)
	local highResult = workspace:Raycast(rootPart.Position + Vector3.new(0, 3, 0), flat.Unit * 3, params)
	if highResult and highResult.Instance.CanCollide then
		return false
	end
	return true
end

-- het "brein" van één zombie; draait in zijn eigen taak tot hij sterft.
-- CoD-logica: zie je de speler? recht erop af. Muur ertussen? routeplanner aan.
local function runZombie(model)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	local rootPart = model.PrimaryPart
	local zombieConfig = Config.Zombie

	local path = PathfindingService:CreatePath({
		AgentRadius = 2.5,
		AgentHeight = 5,
		AgentCanJump = true,
	})
	local waypoints = nil
	local waypointIndex = 1
	local lastPathComputeAt = 0
	local lastAttackTime = 0
	local lastJumpAt = 0

	humanoid.Died:Connect(function()
		task.delay(zombieConfig.DespawnDelay, function()
			model:Destroy()
		end)
	end)

	while model.Parent and humanoid.Health > 0 do
		local target, distance = nearestAlivePlayer(rootPart.Position)
		if target then
			-- mep als we dichtbij genoeg zijn en de cooldown voorbij is
			if distance <= zombieConfig.AttackRange and os.clock() - lastAttackTime >= zombieConfig.AttackCooldown then
				lastAttackTime = os.clock()
				local targetHumanoid = target.Parent and target.Parent:FindFirstChildOfClass("Humanoid")
				if targetHumanoid then
					-- IRON HIDE-kaart: tijdelijk halve schade voor deze speler
					local targetPlayer = Players:GetPlayerFromCharacter(target.Parent)
					local resist = targetPlayer and targetPlayer:GetAttribute("Card_DamageResist") or 1
					targetHumanoid:TakeDamage(zombieConfig.Damage * resist)
				end
			end

			-- waar lopen we naartoe?
			local moveGoal
			if hasLineOfSight(rootPart.Position, target) then
				-- vrij zicht: recht op de speler af (het enge CoD-gevoel)
				waypoints = nil
				moveGoal = target.Position
			else
				-- muur ertussen: routeplanner (vers pad als het oude op/verlopen is)
				if not waypoints or waypointIndex > #waypoints or os.clock() - lastPathComputeAt > 1.5 then
					local ok = pcall(function()
						path:ComputeAsync(rootPart.Position, target.Position)
					end)
					if ok and path.Status == Enum.PathStatus.Success then
						waypoints = path:GetWaypoints()
						waypointIndex = 2 -- nr 1 is onze eigen positie
						lastPathComputeAt = os.clock()
					else
						waypoints = nil
					end
				end
				local waypoint = waypoints and waypoints[waypointIndex]
				if waypoint then
					if waypoint.Action == Enum.PathWaypointAction.Jump then
						humanoid.Jump = true
					end
					moveGoal = waypoint.Position
					if (rootPart.Position - waypoint.Position).Magnitude < 4 then
						waypointIndex += 1
					end
				else
					moveGoal = target.Position -- geen pad te vinden: dan maar recht erop af
				end
			end
			humanoid:MoveTo(moveGoal)

			-- voelspriet: obstakel vlak voor je neus? METEEN springen (niet eerst duwen)
			if os.clock() - lastJumpAt > 0.8
				and humanoid.FloorMaterial ~= Enum.Material.Air
				and obstacleAhead(rootPart, moveGoal - rootPart.Position)
			then
				humanoid.Jump = true
				lastJumpAt = os.clock()
			end
		end
		task.wait(0.2)
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
