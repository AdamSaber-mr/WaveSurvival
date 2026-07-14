-- NOODHERSTEL-SCRIPT deel 3: herbouwt alle wapen-modellen (v2, gedetailleerd).
-- Draai na tools/rebuild-world.luau. Bouwt: StarterPack.Pistol en
-- ServerStorage.Weapons.SMG/Shotgun/RayGun — elk met een onzichtbare
-- "Muzzle"-marker (daar vertrekken tracer en mondingsvuur).

local function gp(props, parent)
	local p = Instance.new("Part")
	p.CanCollide = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.Metal
	for k, v in pairs(props) do p[k] = v end
	p.Parent = parent
	return p
end
local function weldAll(tool)
	local handle = tool:FindFirstChild("Handle")
	for _, p in ipairs(tool:GetChildren()) do
		if p:IsA("BasePart") and p ~= handle then
			local w = Instance.new("WeldConstraint"); w.Part0 = handle; w.Part1 = p; w.Parent = handle
		end
	end
end
local DARK = Color3.fromRGB(35, 35, 42)
local FRAME = Color3.fromRGB(55, 55, 65)
local STEEL = Color3.fromRGB(78, 78, 90)
local INSET = Color3.fromRGB(45, 45, 55)
local WOOD = Color3.fromRGB(112, 76, 52)

local sp = game:GetService("StarterPack")
local ss = game:GetService("ServerStorage")
local weaponsF = ss:FindFirstChild("Weapons")
if not weaponsF then
	weaponsF = Instance.new("Folder"); weaponsF.Name = "Weapons"; weaponsF.Parent = ss
end

-- ---------- PISTOL ----------
local oldP = sp:FindFirstChild("Pistol"); if oldP then oldP:Destroy() end
local pistol = Instance.new("Tool")
pistol.Name = "Pistol"; pistol.ToolTip = "Pistol"; pistol.CanBeDropped = false
local h = gp({Name="Handle", Size=Vector3.new(0.4, 1.0, 0.55), Color=DARK}, pistol)
gp({Name="GripBand", Size=Vector3.new(0.42, 0.45, 0.57), Color=INSET}, pistol).CFrame = h.CFrame * CFrame.new(0, -0.1, 0)
gp({Name="MagBase", Size=Vector3.new(0.44, 0.12, 0.58), Color=INSET}, pistol).CFrame = h.CFrame * CFrame.new(0, -0.55, 0)
gp({Name="Frame", Size=Vector3.new(0.42, 0.3, 1.5), Color=FRAME}, pistol).CFrame = h.CFrame * CFrame.new(0, 0.55, -0.35)
gp({Name="Slide", Size=Vector3.new(0.46, 0.34, 1.6), Color=STEEL}, pistol).CFrame = h.CFrame * CFrame.new(0, 0.86, -0.35)
gp({Name="SlideSerration", Size=Vector3.new(0.47, 0.2, 0.35), Color=INSET}, pistol).CFrame = h.CFrame * CFrame.new(0, 0.86, 0.32)
gp({Name="EjectPort", Size=Vector3.new(0.04, 0.18, 0.42), Color=Color3.fromRGB(25, 25, 30)}, pistol).CFrame = h.CFrame * CFrame.new(0.24, 0.88, -0.2)
local pb = gp({Name="BarrelTip", Shape=Enum.PartType.Cylinder, Size=Vector3.new(0.22, 0.18, 0.18), Color=Color3.fromRGB(28, 28, 34)}, pistol)
pb.CFrame = h.CFrame * CFrame.new(0, 0.86, -1.22) * CFrame.Angles(0, math.rad(90), 0)
gp({Name="FrontSight", Size=Vector3.new(0.06, 0.12, 0.08), Color=Color3.fromRGB(140, 255, 150), Material=Enum.Material.Neon}, pistol).CFrame = h.CFrame * CFrame.new(0, 1.08, -1.05)
gp({Name="RearSight", Size=Vector3.new(0.2, 0.1, 0.08), Color=INSET}, pistol).CFrame = h.CFrame * CFrame.new(0, 1.07, 0.35)
gp({Name="TriggerGuardBottom", Size=Vector3.new(0.1, 0.08, 0.55), Color=FRAME}, pistol).CFrame = h.CFrame * CFrame.new(0, 0.22, -0.52)
gp({Name="TriggerGuardFront", Size=Vector3.new(0.1, 0.3, 0.08), Color=FRAME}, pistol).CFrame = h.CFrame * CFrame.new(0, 0.35, -0.76)
gp({Name="Trigger", Size=Vector3.new(0.07, 0.2, 0.06), Color=STEEL}, pistol).CFrame = h.CFrame * CFrame.new(0, 0.36, -0.48)
local pm = gp({Name="Muzzle", Size=Vector3.new(0.1, 0.1, 0.1), Transparency=1}, pistol)
pm.CFrame = h.CFrame * CFrame.new(0, 0.86, -1.35)
weldAll(pistol)
pistol.GripPos = Vector3.new(0, -0.1, 0.05)
pistol.Parent = sp

-- ---------- SMG ----------
local oldS = weaponsF:FindFirstChild("SMG"); if oldS then oldS:Destroy() end
local smg = Instance.new("Tool")
smg.Name = "SMG"; smg.ToolTip = "SMG — hold to fire"; smg.CanBeDropped = false
local sh = gp({Name="Handle", Size=Vector3.new(0.4, 0.95, 0.5), Color=DARK}, smg)
gp({Name="Receiver", Size=Vector3.new(0.5, 0.55, 2.4), Color=FRAME}, smg).CFrame = sh.CFrame * CFrame.new(0, 0.72, -0.55)
gp({Name="TopRail", Size=Vector3.new(0.42, 0.12, 2.2), Color=INSET}, smg).CFrame = sh.CFrame * CFrame.new(0, 1.05, -0.55)
local shroud = gp({Name="Shroud", Shape=Enum.PartType.Cylinder, Size=Vector3.new(0.95, 0.34, 0.34), Color=Color3.fromRGB(30, 30, 36)}, smg)
shroud.CFrame = sh.CFrame * CFrame.new(0, 0.82, -2.1) * CFrame.Angles(0, math.rad(90), 0)
for i = 0, 1 do
	local ringp = gp({Name="ShroudRing", Shape=Enum.PartType.Cylinder, Size=Vector3.new(0.08, 0.42, 0.42), Color=STEEL}, smg)
	ringp.CFrame = sh.CFrame * CFrame.new(0, 0.82, -1.85 - i * 0.45) * CFrame.Angles(0, math.rad(90), 0)
end
gp({Name="MagTop", Size=Vector3.new(0.32, 0.9, 0.5), Color=INSET}, smg).CFrame = sh.CFrame * CFrame.new(0, 0.05, -0.85) * CFrame.Angles(math.rad(10), 0, 0)
gp({Name="MagBottom", Size=Vector3.new(0.32, 0.75, 0.48), Color=Color3.fromRGB(28, 28, 34)}, smg).CFrame = sh.CFrame * CFrame.new(0, -0.65, -1.0) * CFrame.Angles(math.rad(24), 0, 0)
gp({Name="Foregrip", Size=Vector3.new(0.34, 0.7, 0.4), Color=DARK}, smg).CFrame = sh.CFrame * CFrame.new(0, 0.25, -1.5)
gp({Name="StockRod", Size=Vector3.new(0.14, 0.14, 1.0), Color=STEEL}, smg).CFrame = sh.CFrame * CFrame.new(0, 0.78, 0.8)
gp({Name="ButtPlate", Size=Vector3.new(0.4, 0.68, 0.14), Color=DARK}, smg).CFrame = sh.CFrame * CFrame.new(0, 0.68, 1.32)
gp({Name="FrontSight", Size=Vector3.new(0.06, 0.16, 0.08), Color=Color3.fromRGB(140, 255, 150), Material=Enum.Material.Neon}, smg).CFrame = sh.CFrame * CFrame.new(0, 1.2, -1.55)
gp({Name="RearSight", Size=Vector3.new(0.22, 0.14, 0.08), Color=INSET}, smg).CFrame = sh.CFrame * CFrame.new(0, 1.19, 0.15)
gp({Name="ChargingHandle", Size=Vector3.new(0.28, 0.09, 0.2), Color=STEEL}, smg).CFrame = sh.CFrame * CFrame.new(-0.32, 0.92, -1.1)
gp({Name="NeonStrip", Size=Vector3.new(0.04, 0.09, 1.5), Color=Color3.fromRGB(90, 200, 255), Material=Enum.Material.Neon}, smg).CFrame = sh.CFrame * CFrame.new(0.28, 0.72, -0.5)
gp({Name="TriggerGuardBottom", Size=Vector3.new(0.1, 0.08, 0.5), Color=FRAME}, smg).CFrame = sh.CFrame * CFrame.new(0, 0.24, -0.45)
gp({Name="Trigger", Size=Vector3.new(0.07, 0.18, 0.06), Color=STEEL}, smg).CFrame = sh.CFrame * CFrame.new(0, 0.37, -0.42)
local sm = gp({Name="Muzzle", Size=Vector3.new(0.1, 0.1, 0.1), Transparency=1}, smg)
sm.CFrame = sh.CFrame * CFrame.new(0, 0.82, -2.62)
weldAll(smg)
smg.GripPos = Vector3.new(0, -0.1, 0.05)
smg.Parent = weaponsF

-- ---------- SHOTGUN ----------
local oldG = weaponsF:FindFirstChild("Shotgun"); if oldG then oldG:Destroy() end
local sgun = Instance.new("Tool")
sgun.Name = "Shotgun"; sgun.ToolTip = "Shotgun — devastating up close"; sgun.CanBeDropped = false
local gh = gp({Name="Handle", Size=Vector3.new(0.42, 0.9, 0.55), Color=WOOD, Material=Enum.Material.WoodPlanks}, sgun)
gp({Name="Receiver", Size=Vector3.new(0.5, 0.6, 1.4), Color=Color3.fromRGB(62, 52, 44)}, sgun).CFrame = gh.CFrame * CFrame.new(0, 0.72, -0.4)
local barrel = gp({Name="Barrel", Shape=Enum.PartType.Cylinder, Size=Vector3.new(2.3, 0.3, 0.3), Color=Color3.fromRGB(40, 40, 48)}, sgun)
barrel.CFrame = gh.CFrame * CFrame.new(0, 0.94, -2.1) * CFrame.Angles(0, math.rad(90), 0)
local magTube = gp({Name="MagTube", Shape=Enum.PartType.Cylinder, Size=Vector3.new(1.9, 0.23, 0.23), Color=STEEL}, sgun)
magTube.CFrame = gh.CFrame * CFrame.new(0, 0.62, -1.9) * CFrame.Angles(0, math.rad(90), 0)
gp({Name="Pump", Size=Vector3.new(0.44, 0.42, 0.85), Color=WOOD, Material=Enum.Material.WoodPlanks}, sgun).CFrame = gh.CFrame * CFrame.new(0, 0.63, -1.55)
for i = 0, 2 do
	gp({Name="PumpRib", Size=Vector3.new(0.46, 0.05, 0.1), Color=Color3.fromRGB(80, 55, 38)}, sgun).CFrame = gh.CFrame * CFrame.new(0, 0.63, -1.3 - i * 0.25)
end
gp({Name="Stock", Size=Vector3.new(0.42, 0.5, 1.15), Color=WOOD, Material=Enum.Material.WoodPlanks}, sgun).CFrame = gh.CFrame * CFrame.new(0, 0.55, 0.72) * CFrame.Angles(math.rad(6), 0, 0)
gp({Name="ButtPad", Size=Vector3.new(0.44, 0.6, 0.16), Color=Color3.fromRGB(25, 25, 30), Material=Enum.Material.SmoothPlastic}, sgun).CFrame = gh.CFrame * CFrame.new(0, 0.48, 1.32) * CFrame.Angles(math.rad(6), 0, 0)
gp({Name="BeadSight", Size=Vector3.new(0.07, 0.09, 0.07), Color=Color3.fromRGB(255, 200, 120), Material=Enum.Material.Neon}, sgun).CFrame = gh.CFrame * CFrame.new(0, 1.14, -3.1)
for i = 0, 3 do
	local shell = gp({Name="Shell", Shape=Enum.PartType.Cylinder, Size=Vector3.new(0.26, 0.13, 0.13), Color=Color3.fromRGB(190, 50, 50), Material=Enum.Material.SmoothPlastic}, sgun)
	shell.CFrame = gh.CFrame * CFrame.new(0.3, 0.85, -0.7 + i * 0.22) * CFrame.Angles(0, math.rad(90), 0)
end
gp({Name="TriggerGuardBottom", Size=Vector3.new(0.1, 0.08, 0.5), Color=Color3.fromRGB(62, 52, 44)}, sgun).CFrame = gh.CFrame * CFrame.new(0, 0.25, -0.35)
gp({Name="Trigger", Size=Vector3.new(0.07, 0.18, 0.06), Color=STEEL}, sgun).CFrame = gh.CFrame * CFrame.new(0, 0.38, -0.32)
local gm = gp({Name="Muzzle", Size=Vector3.new(0.1, 0.1, 0.1), Transparency=1}, sgun)
gm.CFrame = gh.CFrame * CFrame.new(0, 0.94, -3.3)
weldAll(sgun)
sgun.GripPos = Vector3.new(0, -0.1, 0.05)
sgun.Parent = weaponsF

-- ---------- RAYGUN ----------
local oldR = weaponsF:FindFirstChild("RayGun"); if oldR then oldR:Destroy() end
local rgun = Instance.new("Tool")
rgun.Name = "RayGun"; rgun.ToolTip = "Ray Gun — the jackpot"; rgun.CanBeDropped = false
local rh = gp({Name="Handle", Size=Vector3.new(0.42, 0.95, 0.5), Color=Color3.fromRGB(35, 40, 38)}, rgun)
local bulb = gp({Name="Body", Shape=Enum.PartType.Ball, Size=Vector3.new(0.9, 0.9, 0.9), Color=Color3.fromRGB(52, 62, 58)}, rgun)
bulb.CFrame = rh.CFrame * CFrame.new(0, 0.72, -0.25)
local taper = gp({Name="Taper", Shape=Enum.PartType.Cylinder, Size=Vector3.new(1.1, 0.55, 0.55), Color=Color3.fromRGB(60, 72, 66)}, rgun)
taper.CFrame = rh.CFrame * CFrame.new(0, 0.78, -1.0) * CFrame.Angles(0, math.rad(90), 0)
for i = 0, 2 do
	local ringp = gp({Name="GlowRing", Shape=Enum.PartType.Cylinder, Size=Vector3.new(0.07, 0.68, 0.68), Color=Color3.fromRGB(80, 255, 120), Material=Enum.Material.Neon}, rgun)
	ringp.CFrame = rh.CFrame * CFrame.new(0, 0.78, -0.7 - i * 0.32) * CFrame.Angles(0, math.rad(90), 0)
end
local dish = gp({Name="Dish", Shape=Enum.PartType.Cylinder, Size=Vector3.new(0.14, 0.95, 0.95), Color=STEEL}, rgun)
dish.CFrame = rh.CFrame * CFrame.new(0, 0.78, -1.6) * CFrame.Angles(0, math.rad(90), 0)
local core = gp({Name="Core", Shape=Enum.PartType.Cylinder, Size=Vector3.new(0.35, 0.28, 0.28), Color=Color3.fromRGB(120, 255, 160), Material=Enum.Material.Neon}, rgun)
core.CFrame = rh.CFrame * CFrame.new(0, 0.78, -1.75) * CFrame.Angles(0, math.rad(90), 0)
local coreLight = Instance.new("PointLight"); coreLight.Color = Color3.fromRGB(80, 255, 120); coreLight.Range = 7; coreLight.Brightness = 0.9; coreLight.Parent = core
for i = 0, 2 do
	gp({Name="Coil", Shape=Enum.PartType.Ball, Size=Vector3.new(0.17, 0.17, 0.17), Color=Color3.fromRGB(80, 255, 120), Material=Enum.Material.Neon}, rgun).CFrame = rh.CFrame * CFrame.new(0, 1.22 - i * 0.06, -0.25 - i * 0.3)
end
gp({Name="Gauge", Size=Vector3.new(0.05, 0.2, 0.26), Color=Color3.fromRGB(255, 200, 90), Material=Enum.Material.Neon}, rgun).CFrame = rh.CFrame * CFrame.new(0.26, 0.9, 0.05)
local ant = gp({Name="Antenna", Size=Vector3.new(0.05, 0.55, 0.05), Color=STEEL}, rgun)
ant.CFrame = rh.CFrame * CFrame.new(0, 1.45, 0.15) * CFrame.Angles(math.rad(-15), 0, 0)
gp({Name="AntennaTip", Shape=Enum.PartType.Ball, Size=Vector3.new(0.13, 0.13, 0.13), Color=Color3.fromRGB(255, 120, 120), Material=Enum.Material.Neon}, rgun).CFrame = rh.CFrame * CFrame.new(0, 1.72, 0.08)
gp({Name="TriggerGuardBottom", Size=Vector3.new(0.1, 0.08, 0.5), Color=Color3.fromRGB(45, 52, 48)}, rgun).CFrame = rh.CFrame * CFrame.new(0, 0.24, -0.4)
gp({Name="Trigger", Size=Vector3.new(0.07, 0.18, 0.06), Color=STEEL}, rgun).CFrame = rh.CFrame * CFrame.new(0, 0.37, -0.37)
local rm = gp({Name="Muzzle", Size=Vector3.new(0.1, 0.1, 0.1), Transparency=1}, rgun)
rm.CFrame = rh.CFrame * CFrame.new(0, 0.78, -1.95)
weldAll(rgun)
rgun.GripPos = Vector3.new(0, -0.1, 0.05)
rgun.Parent = weaponsF

print("[Weapons] 4 wapens herbouwd: Pistol, SMG, Shotgun, RayGun (met Muzzle-markers)")
