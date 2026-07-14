-- WeaponServer: de scheidsrechter van het schieten én de munitie-administratie.
-- De client (tv) vraagt "schiet!" of "herlaad!" — de server beslist alles:
-- heb je kogels? ben je aan het herladen? klopt de vuursnelheid?
-- Ammo staat als stickers (Attributes) op het wapen zelf: Mag, Reserve, Reloading.
-- Die stickers kopieert Roblox automatisch naar de client — de HUD kijkt er zo naar.

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
local reloadEvent = Instance.new("RemoteEvent")
reloadEvent.Name = "ReloadWeapon"
reloadEvent.Parent = remotes

local lastShotAt = {} -- [player] = tijdstip laatste schot (voor vuursnelheid-limiet)
local rng = Random.new()

-- ===== MUNITIE-ADMINISTRATIE =====

-- geef een wapen zijn start-ammo-stickers (één keer, zodra het bestaat)
local function initAmmo(tool)
	local weaponConfig = Config.Weapons[tool.Name]
	if not weaponConfig or not weaponConfig.MagSize then return end
	if tool:GetAttribute("Mag") ~= nil then return end
	tool:SetAttribute("Mag", weaponConfig.MagSize)
	tool:SetAttribute("Reserve", weaponConfig.ReserveMax)
	tool:SetAttribute("Reloading", false)
end

-- houd rugzak + handen van elke speler in de gaten voor nieuwe wapens
local function watchContainer(container)
	container.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then initAmmo(child) end
	end)
	for _, child in ipairs(container:GetChildren()) do
		if child:IsA("Tool") then initAmmo(child) end
	end
end

local function watchPlayer(player)
	local backpack = player:FindFirstChild("Backpack")
	if backpack then watchContainer(backpack) end
	if player.Character then watchContainer(player.Character) end
	player.CharacterAdded:Connect(function(character)
		watchContainer(character)
		watchContainer(player:WaitForChild("Backpack"))
	end)
end
Players.PlayerAdded:Connect(watchPlayer)
for _, player in ipairs(Players:GetPlayers()) do watchPlayer(player) end

-- ===== SCHIETEN =====

local function drawTracer(fromPosition, toPosition, color)
	local distance = (toPosition - fromPosition).Magnitude
	local beam = Instance.new("Part")
	beam.Anchored = true
	beam.CanCollide = false
	beam.CanQuery = false
	beam.CanTouch = false
	beam.Material = Enum.Material.Neon
	beam.Color = color or Color3.fromRGB(120, 220, 255)
	beam.Size = Vector3.new(0.15, 0.15, distance)
	beam.CFrame = CFrame.lookAt(fromPosition, toPosition) * CFrame.new(0, 0, -distance / 2)
	beam.Parent = workspace
	Debris:AddItem(beam, 0.08)
end

local function damageZombie(player, zombieHumanoid, weaponConfig)
	local wasAlive = zombieHumanoid.Health > 0
	-- POWER SHOT-kaart: tijdelijk dubbele schade
	local damageBoost = player:GetAttribute("Card_DamageBoost") or 1
	zombieHumanoid:TakeDamage(weaponConfig.Damage * damageBoost)
	if wasAlive then
		EconomyService.add(player, Config.Economy.HitReward)
		if zombieHumanoid.Health <= 0 then
			EconomyService.add(player, Config.Economy.KillReward)
		end
	end
end

-- noodgreep van dichtbij: een straal die BINNENIN een zombie begint kan hem niet
-- raken (Roblox-regel) — dus als de straal niks raakt, checken we of er een zombie
-- praktisch tegen de loop aan staat in de schietrichting
local function pointBlankZombie(origin, aimDirection)
	local zombiesFolder = workspace:FindFirstChild("Zombies")
	if not zombiesFolder then return nil end
	local best, bestDistance = nil, 7  -- max 7 studs "tegen de loop" (de loop zit naast je lijf)
	for _, model in ipairs(zombiesFolder:GetChildren()) do
		local humanoid = model:FindFirstChildOfClass("Humanoid")
		local rootPart = model.PrimaryPart
		if humanoid and rootPart and humanoid.Health > 0 then
			local offset = rootPart.Position - origin
			local distance = offset.Magnitude
			if distance < bestDistance and offset.Unit:Dot(aimDirection.Unit) > 0.3 then
				best, bestDistance = humanoid, distance
			end
		end
	end
	return best
end

-- mondingsvuur: korte flits + vonkjes uit de loop
local function muzzleFlash(position)
	local flash = Instance.new("Part")
	flash.Anchored = true
	flash.CanCollide = false
	flash.CanQuery = false
	flash.CanTouch = false
	flash.Transparency = 1
	flash.Size = Vector3.new(0.2, 0.2, 0.2)
	flash.Position = position
	flash.Parent = workspace
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 200, 90), Color3.fromRGB(255, 120, 40))
	emitter.LightEmission = 1
	emitter.Lifetime = NumberRange.new(0.04, 0.1)
	emitter.Speed = NumberRange.new(4, 9)
	emitter.SpreadAngle = Vector2.new(35, 35)
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45), NumberSequenceKeypoint.new(1, 0) })
	emitter.Enabled = false
	emitter.Parent = flash
	emitter:Emit(8)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 190, 110)
	light.Range = 10
	light.Brightness = 2.4
	light.Parent = flash
	Debris:AddItem(flash, 0.09)
end

-- bloedspetters op het inslagpunt
local function bloodBurst(position)
	local hit = Instance.new("Part")
	hit.Anchored = true
	hit.CanCollide = false
	hit.CanQuery = false
	hit.CanTouch = false
	hit.Transparency = 1
	hit.Size = Vector3.new(0.2, 0.2, 0.2)
	hit.Position = position
	hit.Parent = workspace
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(Color3.fromRGB(140, 20, 20), Color3.fromRGB(80, 10, 10))
	emitter.Lifetime = NumberRange.new(0.25, 0.5)
	emitter.Speed = NumberRange.new(3, 7)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Acceleration = Vector3.new(0, -22, 0)
	emitter.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.28), NumberSequenceKeypoint.new(1, 0.05) })
	emitter.Enabled = false
	emitter.Parent = hit
	emitter:Emit(10)
	Debris:AddItem(hit, 0.6)
end

-- één straal: tracer + schade + geld bij een zombie-raak
-- (de straal vertrekt vanaf ooghoogte — stabiel; de tracer tekent vanaf de loop — mooi)
local function fireRay(player, character, origin, tracerOrigin, direction, weaponConfig)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character }
	local result = workspace:Raycast(origin, direction, params)

	local hitPosition = result and result.Position or (origin + direction)
	drawTracer(tracerOrigin, hitPosition, weaponConfig.TracerColor)

	local zombieHumanoid = nil
	if result and result.Instance then
		local model = result.Instance:FindFirstAncestorOfClass("Model")
		local foundHumanoid = model and model:FindFirstChildOfClass("Humanoid")
		local zombiesFolder = workspace:FindFirstChild("Zombies")
		if foundHumanoid and zombiesFolder and model.Parent == zombiesFolder then
			zombieHumanoid = foundHumanoid
		end
	end

	-- niks geraakt? misschien staat de zombie tegen je loop aan
	if not zombieHumanoid then
		zombieHumanoid = pointBlankZombie(origin, direction)
	end

	if zombieHumanoid then
		damageZombie(player, zombieHumanoid, weaponConfig)
		bloodBurst(hitPosition)
	end
end

fireEvent.OnServerEvent:Connect(function(player, targetPosition)
	if typeof(targetPosition) ~= "Vector3" then return end

	if player:GetAttribute("Spectator") == true then return end -- geesten schieten niet
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if not (humanoid and rootPart and humanoid.Health > 0) then return end
	local tool = character:FindFirstChildOfClass("Tool")
	local weaponConfig = tool and Config.Weapons[tool.Name]
	if not weaponConfig then return end

	initAmmo(tool)

	-- magazijn leeg? geen schot (client vraagt dan zelf om een reload)
	local mag = tool:GetAttribute("Mag") or 0
	if mag <= 0 then return end

	-- aan het herladen? shotgun mag onderbreken (pump-actie!), de rest moet wachten
	if tool:GetAttribute("Reloading") then
		if weaponConfig.ShellReload then
			tool:SetAttribute("Reloading", false)
		else
			return
		end
	end

	local now = os.clock()
	if lastShotAt[player] and now - lastShotAt[player] < weaponConfig.FireCooldown then return end
	lastShotAt[player] = now

	-- AIM-FIX: de straal vertrekt vanaf ooghoogte (stabiel punt) en niet vanuit de
	-- loop — die zwaait mee met je rennende arm en stuurde kogels de verkeerde kant op.
	local origin = rootPart.Position + Vector3.new(0, 1.5, 0)
	local muzzle = tool:FindFirstChild("Muzzle")
	local handle = tool:FindFirstChild("Handle")
	local tracerOrigin = (muzzle and muzzle.Position) or (handle and handle.Position) or origin
	if (targetPosition - origin).Magnitude < 0.001 then return end

	-- kogel eraf
	tool:SetAttribute("Mag", mag - 1)
	muzzleFlash(tracerOrigin)

	-- shotgun: waaier van kogeltjes; andere wapens: één straal
	local pellets = weaponConfig.Pellets or 1
	local spread = weaponConfig.Spread or 0
	local aimFrame = CFrame.lookAt(origin, targetPosition)
	for _ = 1, pellets do
		local yaw = math.rad(rng:NextNumber(-spread, spread))
		local pitch = math.rad(rng:NextNumber(-spread, spread))
		local direction = (aimFrame * CFrame.Angles(pitch, yaw, 0)).LookVector * weaponConfig.Range
		fireRay(player, character, origin, tracerOrigin, direction, weaponConfig)
	end
end)

-- ===== HERLADEN =====

reloadEvent.OnServerEvent:Connect(function(player)
	local character = player.Character
	local tool = character and character:FindFirstChildOfClass("Tool")
	local weaponConfig = tool and Config.Weapons[tool.Name]
	if not weaponConfig or not weaponConfig.MagSize then return end

	initAmmo(tool)
	if tool:GetAttribute("Reloading") then return end

	local mag = tool:GetAttribute("Mag") or 0
	local reserve = tool:GetAttribute("Reserve") or 0
	if mag >= weaponConfig.MagSize then return end  -- al vol
	if reserve == 0 then return end                  -- niks om mee te laden (-1 = oneindig, mag door)

	tool:SetAttribute("Reloading", true)

	-- Speed Cola: herladen 2x zo snel
	local reloadMultiplier = 1
	if player:GetAttribute("Perk_SpeedCola") and Config.Perks.SpeedCola.ReloadMultiplier then
		reloadMultiplier = Config.Perks.SpeedCola.ReloadMultiplier
	end

	if weaponConfig.ShellReload then
		-- shotgun: schelp voor schelp; een schot of wapenwissel onderbreekt netjes
		while tool.Parent == character
			and tool:GetAttribute("Reloading")
			and (tool:GetAttribute("Mag") or 0) < weaponConfig.MagSize
			and (tool:GetAttribute("Reserve") or 0) ~= 0
		do
			task.wait(weaponConfig.ShellReloadTime * reloadMultiplier)
			if not tool:GetAttribute("Reloading") or tool.Parent ~= character then break end
			local currentMag = tool:GetAttribute("Mag") or 0
			local currentReserve = tool:GetAttribute("Reserve") or 0
			if currentMag >= weaponConfig.MagSize then break end
			tool:SetAttribute("Mag", currentMag + 1)
			if currentReserve > 0 then
				tool:SetAttribute("Reserve", currentReserve - 1)
			end
		end
	else
		-- pistol/SMG: heel magazijn in één keer
		task.wait(weaponConfig.ReloadTime * reloadMultiplier)
		if tool.Parent == character and tool:GetAttribute("Reloading") then
			local currentMag = tool:GetAttribute("Mag") or 0
			local currentReserve = tool:GetAttribute("Reserve") or 0
			local needed = weaponConfig.MagSize - currentMag
			local taken = (currentReserve < 0) and needed or math.min(needed, currentReserve)
			tool:SetAttribute("Mag", currentMag + taken)
			if currentReserve > 0 then
				tool:SetAttribute("Reserve", currentReserve - taken)
			end
		end
	end

	tool:SetAttribute("Reloading", false)
end)

Players.PlayerRemoving:Connect(function(player)
	lastShotAt[player] = nil
end)
