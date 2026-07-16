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
		-- geesten (spectators) ruiken zombies niet: die worden volledig genegeerd
		if humanoid and rootPart and humanoid.Health > 0 and player:GetAttribute("Spectator") ~= true then
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
		-- groene "poef" bij de dood
		if rootPart then
			local burst = Instance.new("ParticleEmitter")
			burst.Color = ColorSequence.new(Color3.fromRGB(140, 200, 110))
			burst.Lifetime = NumberRange.new(0.4, 0.9)
			burst.Speed = NumberRange.new(3, 6)
			burst.SpreadAngle = Vector2.new(180, 180)
			burst.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
			burst.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) })
			burst.Enabled = false
			burst.Parent = rootPart
			burst:Emit(18)
		end
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

-- spawn één zombie op een marker: hij KLIMT uit de grond omhoog (met stofwolk)
function ZombieService.spawn(marker, statOverrides)
	local zombie = ZombieFactory.create(statOverrides)
	zombie.Parent = zombiesFolder
	local targetCF = CFrame.new(marker.Position + Vector3.new(0, 2, 0))
		* CFrame.Angles(0, math.rad(Random.new():NextNumber(0, 360)), 0)
	local rootPart = zombie.PrimaryPart

	-- start onder de grond, vastgezet
	rootPart.Anchored = true
	zombie:PivotTo(targetCF * CFrame.new(0, -3.4, 0))

	-- stofwolk op de uitklim-plek
	local dust = Instance.new("ParticleEmitter")
	dust.Color = ColorSequence.new(Color3.fromRGB(120, 115, 100))
	dust.Lifetime = NumberRange.new(0.6, 1.2)
	dust.Speed = NumberRange.new(1.5, 3.5)
	dust.SpreadAngle = Vector2.new(70, 70)
	dust.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 2.2) })
	dust.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1) })
	dust.Enabled = false
	dust.Parent = rootPart
	dust:Emit(22)

	-- aardkluiten die opspatten (zwaarder, vallen snel terug)
	local dirt = Instance.new("ParticleEmitter")
	dirt.Color = ColorSequence.new(Color3.fromRGB(88, 74, 58))
	dirt.Lifetime = NumberRange.new(0.4, 0.8)
	dirt.Speed = NumberRange.new(6, 12)
	dirt.SpreadAngle = Vector2.new(35, 35)
	dirt.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0.15) })
	dirt.Acceleration = Vector3.new(0, -60, 0)
	dirt.Enabled = false
	dirt.Parent = rootPart
	dirt:Emit(12)

	-- opengebarsten grond: donkere plek met scheur-lijnen die langzaam vervaagt
	local crack = Instance.new("Model")
	crack.Name = "GroundCrack"
	local patch = Instance.new("Part")
	patch.Anchored = true; patch.CanCollide = false; patch.CanQuery = false; patch.CanTouch = false
	patch.Material = Enum.Material.Slate
	patch.Color = Color3.fromRGB(38, 32, 26)
	patch.Size = Vector3.new(4.2, 0.06, 4.2)
	patch.CFrame = CFrame.new(marker.Position.X, 1.08, marker.Position.Z)
		* CFrame.Angles(0, math.rad(Random.new():NextNumber(0, 360)), 0)
	patch.Parent = crack
	for i = 1, 4 do
		local line = Instance.new("Part")
		line.Anchored = true; line.CanCollide = false; line.CanQuery = false; line.CanTouch = false
		line.Material = Enum.Material.SmoothPlastic
		line.Color = Color3.fromRGB(16, 14, 12)
		line.Size = Vector3.new(0.14, 0.02, 2 + i * 0.5)
		line.CFrame = patch.CFrame * CFrame.new(0, 0.05, 0) * CFrame.Angles(0, math.rad(i * 87), 0) * CFrame.new(0, 0, 1.2)
		line.Parent = crack
	end
	crack.Parent = workspace
	task.delay(9, function()
		-- rustig laten vervagen, dan opruimen
		for step = 1, 10 do
			for _, piece in ipairs(crack:GetChildren()) do
				piece.Transparency = step / 10
			end
			task.wait(0.12)
		end
		crack:Destroy()
	end)

	-- omhoog klimmen (~0.9s), dan pas jagen
	task.spawn(function()
		local riseTime = 0.9
		local elapsed = 0
		while elapsed < riseTime and zombie.Parent do
			local deltaTime = task.wait()
			elapsed += deltaTime
			local progress = math.min(elapsed / riseTime, 1)
			-- ease-out: snel begin, zachte landing
			local height = -3.4 * (1 - progress) * (1 - progress * 0.3)
			zombie:PivotTo(targetCF * CFrame.new(0, height, 0))
		end
		if zombie.Parent and rootPart then
			zombie:PivotTo(targetCF)
			rootPart.Anchored = false
			task.spawn(runZombie, zombie)
		end
	end)
	return zombie
end

-- alles opruimen (bij een game-reset)
function ZombieService.clearAll()
	for _, zombie in ipairs(zombiesFolder:GetChildren()) do
		zombie:Destroy()
	end
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
