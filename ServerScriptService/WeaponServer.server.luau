-- WeaponServer: de scheidsrechter van het schieten.
-- De client (tv) vraagt "ik wil schieten richting X" — de server controleert alles,
-- schiet de échte straal (raycast) en deelt de schade uit. Zo kan niemand valsspelen.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local EconomyService = require(script.Parent:WaitForChild("EconomyService"))

-- walkietalkie-map: in code aangemaakt zodat alles in git zichtbaar is
local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
end
local fireEvent = Instance.new("RemoteEvent")
fireEvent.Name = "FireWeapon"
fireEvent.Parent = remotes

local lastShotAt = {} -- [player] = tijdstip laatste schot (voor vuursnelheid-limiet)

-- kort lichtstreepje van loop naar inslag, zodat je ziet waar je schiet
local function drawTracer(fromPosition, toPosition)
	local distance = (toPosition - fromPosition).Magnitude
	local beam = Instance.new("Part")
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanQuery = false
	beam.CanTouch = false
	beam.Material = Enum.Material.Neon
	beam.Color = Color3.fromRGB(120, 220, 255)
	beam.Size = Vector3.new(0.15, 0.15, distance)
	beam.CFrame = CFrame.lookAt(fromPosition, toPosition) * CFrame.new(0, 0, -distance / 2)
	beam.Parent = workspace
	Debris:AddItem(beam, 0.08)
end

fireEvent.OnServerEvent:Connect(function(player, targetPosition)
	-- controle 1: is de aanvraag wel een echte positie?
	if typeof(targetPosition) ~= "Vector3" then return end

	local weaponConfig = Config.Weapons.Pistol

	-- controle 2: leeft de speler en heeft hij het wapen vast?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not (humanoid and rootPart and humanoid.Health > 0) then return end
	local tool = character:FindFirstChild("Pistol")
	if not tool then return end

	-- controle 3: niet sneller schieten dan de vuursnelheid toestaat
	local now = os.clock()
	if lastShotAt[player] and now - lastShotAt[player] < weaponConfig.FireCooldown then return end
	lastShotAt[player] = now

	-- de echte straal: vanaf de loop richting het doelpunt
	local handle = tool:FindFirstChild("Handle")
	local origin = handle and handle.Position or rootPart.Position
	local direction = targetPosition - origin
	if direction.Magnitude < 0.001 then return end
	direction = direction.Unit * weaponConfig.Range

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local result = workspace:Raycast(origin, direction, params)

	local hitPosition = result and result.Position or (origin + direction)
	drawTracer(origin, hitPosition)

	-- raak? alleen zombies (modellen in de Zombies-map) krijgen schade
	if result and result.Instance then
		local model = result.Instance:FindFirstAncestorOfClass("Model")
		local zombieHumanoid = model and model:FindFirstChildOfClass("Humanoid")
		local zombiesFolder = workspace:FindFirstChild("Zombies")
		if zombieHumanoid and zombiesFolder and model.Parent == zombiesFolder then
			local wasAlive = zombieHumanoid.Health > 0
			zombieHumanoid:TakeDamage(weaponConfig.Damage)
			if wasAlive then
				EconomyService.add(player, Config.Economy.HitReward)
				if zombieHumanoid.Health <= 0 then
					-- het dodelijke schot: kill-bonus erbovenop
					EconomyService.add(player, Config.Economy.KillReward)
				end
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(player)
	lastShotAt[player] = nil
end)
