-- SceneryService: wekt het decor tot leven.
-- Het reuzenrad draait, ballonnen deinen, het raket-baken knippert, de mystery box
-- pulseert, perk-automaten dampen en het SPACELAND-neon flikkert af en toe spookachtig.
-- Puur sfeer — geen gameplay-invloed.

local RunService = game:GetService("RunService")

local deco = workspace:WaitForChild("Deco", 10)
if not deco then
	warn("[Scenery] geen Deco-map gevonden — polish nog niet gebouwd?")
	return
end

local rng = Random.new()

-- ===== verzamel de bewegende delen =====

-- reuzenrad-spinner
local spinner = nil
local spinnerBasePivot = nil
local spinSpeed = 6
local wheel = deco:FindFirstChild("FerrisWheel")
if wheel then
	spinner = wheel:FindFirstChild("Spinner")
	spinSpeed = wheel:GetAttribute("SpinSpeed") or 6
	if spinner then
		spinnerBasePivot = spinner:GetPivot()
	end
end

-- ballontrossen (met Bob-attribute)
local balloonClusters = {}
for _, model in ipairs(deco:GetChildren()) do
	if model:IsA("Model") and model:GetAttribute("Bob") then
		table.insert(balloonClusters, { model = model, basePivot = model:GetPivot(), phase = rng:NextNumber(0, math.pi * 2) })
	end
end

-- knipperende bakens (met Blink-attribute)
local beacons = {}
for _, descendant in ipairs(deco:GetDescendants()) do
	if descendant:IsA("BasePart") and descendant:GetAttribute("Blink") then
		table.insert(beacons, descendant)
	end
end

-- mystery box: pulserend licht + gouden sprankels
local boxLight, boxCrate
local map = workspace:FindFirstChild("Map")
local mysteryBox = map and map:FindFirstChild("MysteryBox")
if mysteryBox then
	boxCrate = mysteryBox:FindFirstChild("Crate")
	boxLight = boxCrate and boxCrate:FindFirstChildOfClass("PointLight")
	local display = mysteryBox:FindFirstChild("Display")
	if display then
		local sparkle = Instance.new("ParticleEmitter")
		sparkle.Color = ColorSequence.new(Color3.fromRGB(255, 220, 120))
		sparkle.LightEmission = 0.8
		sparkle.Rate = 5
		sparkle.Lifetime = NumberRange.new(1.2, 2)
		sparkle.Speed = NumberRange.new(0.5, 1.2)
		sparkle.SpreadAngle = Vector2.new(180, 180)
		sparkle.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.25), NumberSequenceKeypoint.new(1, 0) })
		sparkle.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
		sparkle.Parent = display
	end
end

-- perk-automaten: zachte stoom uit de gloeiende bovenkant
local perkMachines = map and map:FindFirstChild("PerkMachines")
if perkMachines then
	for _, machine in ipairs(perkMachines:GetChildren()) do
		local top = machine:FindFirstChild("TopGlow")
		if top then
			local steam = Instance.new("ParticleEmitter")
			steam.Color = ColorSequence.new(Color3.fromRGB(230, 230, 240))
			steam.Rate = 1.6
			steam.Lifetime = NumberRange.new(1.8, 3)
			steam.Speed = NumberRange.new(0.8, 1.4)
			steam.Acceleration = Vector3.new(0, 0.6, 0)
			steam.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 2.2) })
			steam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 1) })
			steam.Parent = top
		end
	end
end

-- kapotte stroomkabels bij de spawn-deuren (met Spark-attribute): onregelmatig knetteren
for _, descendant in ipairs(deco:GetDescendants()) do
	if descendant:IsA("BasePart") and descendant:GetAttribute("Spark") then
		local emitter = descendant:FindFirstChildOfClass("ParticleEmitter")
		if emitter then
			task.spawn(function()
				while descendant.Parent do
					task.wait(rng:NextNumber(2, 7))
					-- 1 tot 3 knettertjes vlak achter elkaar
					for _ = 1, rng:NextInteger(1, 3) do
						emitter:Emit(rng:NextInteger(4, 10))
						task.wait(rng:NextNumber(0.08, 0.25))
					end
				end
			end)
		end
	end
end

-- SPACELAND-neonbalk: heel af en toe een spookachtig flikkertje
local archBeam
local zones = map and map:FindFirstChild("Zones")
local plaza = zones and zones:FindFirstChild("SpawnPlaza")
archBeam = plaza and plaza:FindFirstChild("ArchBeam")
if archBeam then
	task.spawn(function()
		while archBeam.Parent do
			task.wait(rng:NextNumber(6, 15))
			for _ = 1, rng:NextInteger(2, 4) do
				archBeam.Material = Enum.Material.SmoothPlastic
				task.wait(0.05)
				archBeam.Material = Enum.Material.Neon
				task.wait(rng:NextNumber(0.05, 0.15))
			end
		end
	end)
end

-- ===== de hoofdklok: alles beweegt in één Heartbeat =====
local elapsed = 0
local blinkTimer = 0
local blinkOn = true

RunService.Heartbeat:Connect(function(deltaTime)
	elapsed += deltaTime

	-- reuzenrad draait statig rond
	if spinner and spinnerBasePivot then
		spinner:PivotTo(spinnerBasePivot * CFrame.Angles(0, 0, math.rad(elapsed * spinSpeed)))
	end

	-- ballonnen deinen zachtjes
	for _, cluster in ipairs(balloonClusters) do
		local offset = math.sin(elapsed * 0.8 + cluster.phase) * 0.4
		cluster.model:PivotTo(cluster.basePivot * CFrame.new(0, offset, 0))
	end

	-- bakens knipperen
	blinkTimer += deltaTime
	if blinkTimer >= 0.7 then
		blinkTimer = 0
		blinkOn = not blinkOn
		for _, beacon in ipairs(beacons) do
			beacon.Transparency = blinkOn and 0 or 0.75
			local light = beacon:FindFirstChildOfClass("PointLight")
			if light then
				light.Enabled = blinkOn
			end
		end
	end

	-- mystery box ademt licht
	if boxLight then
		boxLight.Brightness = 0.9 + math.sin(elapsed * 2.2) * 0.5
	end
end)

print("[Scenery] Spaceland leeft: rad draait, ballonnen deinen, neon flikkert")
