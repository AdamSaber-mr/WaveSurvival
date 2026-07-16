-- ZombieFactory: bouwt de zombies — besmette Spaceland-parkmedewerkers.
-- Elke zombie is uniek: willekeurige huidtint, uniformkleur, grootte en houding.
-- Kenmerken: parkvest met naamplaatje, petje, gloeiende ogen, hangende kaak,
-- voorovergebogen grijp-houding, kledingflarden en bloedsporen.
-- Gedrag zit in ZombieService; dit is puur het "lichaam" + Humanoid.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))

local ZombieFactory = {}

local rng = Random.new()

-- besmette huidtinten
local SKIN_TONES = {
	Color3.fromRGB(110, 160, 90),
	Color3.fromRGB(128, 148, 98),
	Color3.fromRGB(148, 158, 118),
	Color3.fromRGB(96, 132, 96),
	Color3.fromRGB(122, 140, 110),
}
-- Spaceland-uniformen (vestjes)
local UNIFORMS = {
	Color3.fromRGB(96, 44, 128),   -- parkpaars
	Color3.fromRGB(46, 64, 128),   -- ruimteblauw
	Color3.fromRGB(128, 34, 92),   -- magenta
}
local PANTS = Color3.fromRGB(38, 38, 48)
local BLOOD = Color3.fromRGB(96, 22, 22)

local function makePart(props, parent)
	local p = Instance.new("Part")
	p.CanCollide = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in pairs(props) do p[k] = v end
	p.Parent = parent
	return p
end

local function weldTo(root, part)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = part
	weld.Parent = root
end

function ZombieFactory.create(overrides)
	overrides = overrides or {}

	local scale = rng:NextNumber(0.92, 1.15)
	local skin = SKIN_TONES[rng:NextInteger(1, #SKIN_TONES)]
	local skinDark = Color3.new(skin.R * 0.8, skin.G * 0.8, skin.B * 0.8)
	local uniform = UNIFORMS[rng:NextInteger(1, #UNIFORMS)]
	local uniformDark = Color3.new(uniform.R * 0.6, uniform.G * 0.6, uniform.B * 0.6)
	local hunch = math.rad(rng:NextNumber(8, 16))       -- voorover
	local headTilt = math.rad(rng:NextNumber(-12, 12))  -- scheve kop

	local model = Instance.new("Model")
	model.Name = "Zombie"

	-- het onzichtbare "karretje" waar de Humanoid mee stuurt
	local hrp = makePart({Name="HumanoidRootPart", Size=Vector3.new(2, 2, 1) * scale, Transparency=1, CanCollide=true}, model)
	hrp.CFrame = CFrame.new(0, 3 * scale, 0)
	local body = hrp.CFrame * CFrame.Angles(hunch, 0, 0) -- alles hangt iets voorover

	-- romp: broekdeel + vest
	local hips = makePart({Name="Hips", Size=Vector3.new(2, 0.9, 1.05) * scale, Color=PANTS}, model)
	hips.CFrame = body * CFrame.new(0, -0.55 * scale, 0)
	local torso = makePart({Name="Torso", Size=Vector3.new(2, 1.3, 1) * scale, Color=skin}, model)
	torso.CFrame = body * CFrame.new(0, 0.35 * scale, 0)
	local vest = makePart({Name="Vest", Size=Vector3.new(1.84, 1.22, 1.26) * scale, Color=uniform, Material=Enum.Material.Fabric}, model)
	vest.CFrame = body * CFrame.new(0, 0.42 * scale, 0)
	-- naamplaatje op de borst
	local tag = makePart({Name="NameTag", Size=Vector3.new(0.42, 0.22, 0.06) * scale, Color=Color3.fromRGB(235, 235, 240)}, model)
	tag.CFrame = body * CFrame.new(-0.55 * scale, 0.62 * scale, -0.72 * scale)

	-- kledingflarden onder het vest
	for i = 1, 3 do
		local flap = makePart({Name="Flap", Size=Vector3.new(0.5, rng:NextNumber(0.5, 0.9), 0.08) * scale, Color=uniformDark, Material=Enum.Material.Fabric}, model)
		flap.CFrame = body * CFrame.new((-0.7 + i * 0.5) * scale, -0.35 * scale, -0.72 * scale) * CFrame.Angles(math.rad(rng:NextNumber(-15, 5)), 0, math.rad(rng:NextNumber(-10, 10)))
	end

	-- hoofd met pet, ogen en hangende kaak
	local head = makePart({Name="Head", Size=Vector3.new(1.15, 1.05, 1.1) * scale, Color=skin}, model)
	head.CFrame = body * CFrame.new(0, 1.55 * scale, 0.1 * scale) * CFrame.Angles(math.rad(10), 0, headTilt)
	local cap = makePart({Name="Cap", Size=Vector3.new(1.22, 0.32, 1.16) * scale, Color=uniformDark}, model)
	cap.CFrame = head.CFrame * CFrame.new(0, 0.62 * scale, 0.03 * scale) * CFrame.Angles(math.rad(-6), 0, 0)
	local brim = makePart({Name="CapBrim", Size=Vector3.new(1.0, 0.1, 0.55) * scale, Color=uniformDark}, model)
	brim.CFrame = head.CFrame * CFrame.new(0, 0.5 * scale, -0.75 * scale) * CFrame.Angles(math.rad(-10), 0, 0)
	for _, dx in ipairs({ -0.28, 0.28 }) do
		local eye = makePart({Name="Eye", Size=Vector3.new(0.24, 0.18, 0.08) * scale,
			Color=Color3.fromRGB(255, 45, 45), Material=Enum.Material.Neon}, model)
		eye.CFrame = head.CFrame * CFrame.new(dx * scale, 0.08 * scale, -0.61 * scale)
	end
	local jaw = makePart({Name="Jaw", Size=Vector3.new(0.72, 0.28, 0.5) * scale, Color=skinDark}, model)
	jaw.CFrame = head.CFrame * CFrame.new(0, -0.58 * scale, -0.32 * scale) * CFrame.Angles(math.rad(24), 0, 0)

	-- grijp-armen: asymmetrisch vooruit
	local armAngles = { rng:NextNumber(-95, -75), rng:NextNumber(-115, -95) }
	for i, dx in ipairs({ -1.58, 1.58 }) do
		local arm = makePart({Name="Arm", Size=Vector3.new(0.85, 2, 0.85) * scale, Color=skin}, model)
		arm.CFrame = body * CFrame.new(dx * scale, 0.55 * scale, -0.3 * scale) * CFrame.Angles(math.rad(armAngles[i]), 0, math.rad(dx > 0 and -4 or 4))
			* CFrame.new(0, -0.8 * scale, 0)
		local sleeve = makePart({Name="Sleeve", Size=Vector3.new(1.0, 0.7, 1.0) * scale, Color=uniform, Material=Enum.Material.Fabric}, model)
		sleeve.CFrame = arm.CFrame * CFrame.new(0, 0.65 * scale, 0)
		local hand = makePart({Name="Hand", Size=Vector3.new(0.7, 0.5, 0.7) * scale, Color=skinDark}, model)
		hand.CFrame = arm.CFrame * CFrame.new(0, -1.15 * scale, 0) * CFrame.Angles(math.rad(rng:NextNumber(-20, 0)), 0, 0)
	end

	-- benen in loop-stand
	local legAngles = { rng:NextNumber(6, 14), rng:NextNumber(-12, -4) }
	for i, dx in ipairs({ -0.5, 0.5 }) do
		local leg = makePart({Name="Leg", Size=Vector3.new(0.9, 2, 0.9) * scale, Color=PANTS}, model)
		leg.CFrame = hrp.CFrame * CFrame.new(dx * scale, -2 * scale, 0) * CFrame.Angles(math.rad(legAngles[i]), 0, 0)
		local shoe = makePart({Name="Shoe", Size=Vector3.new(0.95, 0.35, 1.15) * scale, Color=Color3.fromRGB(25, 25, 30)}, model)
		shoe.CFrame = leg.CFrame * CFrame.new(0, -1.05 * scale, -0.1 * scale)
	end

	-- bloedsporen
	for i = 1, rng:NextInteger(2, 3) do
		local blood = makePart({Name="Blood", Size=Vector3.new(rng:NextNumber(0.3, 0.7), rng:NextNumber(0.3, 0.6), 0.03) * scale, Color=BLOOD, Material=Enum.Material.Slate}, model)
		local host = (i <= 2) and vest or head
		local depth = (i <= 2) and -0.70 or -0.60
		blood.CFrame = host.CFrame * CFrame.new(rng:NextNumber(-0.5, 0.5) * scale, rng:NextNumber(-0.3, 0.3) * scale, depth * scale)
	end

	-- alles vastlassen aan het karretje
	for _, p in ipairs(model:GetChildren()) do
		if p:IsA("BasePart") and p ~= hrp then
			weldTo(hrp, p)
		end
	end

	local humanoid = Instance.new("Humanoid")
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.NameDisplayDistance = 0
	humanoid.HealthDisplayDistance = 0
	humanoid.MaxHealth = overrides.Health or Config.Zombie.Health
	humanoid.Health = humanoid.MaxHealth
	humanoid.WalkSpeed = (overrides.WalkSpeed or Config.Zombie.WalkSpeed) * rng:NextNumber(0.95, 1.08)
	humanoid.HipHeight = 2 * scale
	humanoid.RequiresNeck = false
	humanoid.Parent = model

	model.PrimaryPart = hrp
	return model
end

return ZombieFactory
