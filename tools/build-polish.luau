-- NOODHERSTEL-SCRIPT deel 2 (fase 11 polish): nacht-atmosfeer + al het decor.
-- Draai EERST tools/rebuild-world.luau (basis-map), daarna dit script.
-- Bouwt: nacht/sterren/bloom, lantaarns, festoen-slingers, neon-pad, spawn-ringen,
-- pilaren, banken/prullenbakken, winkel-aankleding, de grote poort, reuzenrad,
-- raket-toren, planeten, ballonnen en de nacht-fixes (verlichte plantenbakken).
-- Beweging (rad draait etc.) komt uit ServerScriptService/SceneryService.

-- ===== DEEL 1: NACHT-ATMOSFEER =====
local Lighting = game:GetService("Lighting")
for _, name in ipairs({ "SpaceAtmosphere", "SpaceSky", "SpaceBloom", "SpaceColor" }) do
	local old = Lighting:FindFirstChild(name)
	if old then old:Destroy() end
end
Lighting.ClockTime = 19.3
Lighting.Brightness = 2.3
Lighting.GlobalShadows = true
Lighting.EnvironmentDiffuseScale = 0.35
Lighting.EnvironmentSpecularScale = 0.4
Lighting.OutdoorAmbient = Color3.fromRGB(118, 124, 162)
Lighting.Ambient = Color3.fromRGB(92, 96, 124)

local sky = Instance.new("Sky"); sky.Name = "SpaceSky"
sky.StarCount = 4500; sky.SunAngularSize = 8; sky.MoonAngularSize = 14
sky.Parent = Lighting
local atmosphere = Instance.new("Atmosphere"); atmosphere.Name = "SpaceAtmosphere"
atmosphere.Density = 0.22; atmosphere.Offset = 0.3
atmosphere.Color = Color3.fromRGB(110, 118, 165); atmosphere.Decay = Color3.fromRGB(55, 62, 105)
atmosphere.Glare = 0.25; atmosphere.Haze = 1.2
atmosphere.Parent = Lighting
local bloom = Instance.new("BloomEffect"); bloom.Name = "SpaceBloom"
bloom.Intensity = 0.55; bloom.Size = 28; bloom.Threshold = 1.05
bloom.Parent = Lighting
local colorFx = Instance.new("ColorCorrectionEffect"); colorFx.Name = "SpaceColor"
colorFx.Contrast = 0.08; colorFx.Saturation = 0.08; colorFx.TintColor = Color3.fromRGB(235, 240, 255)
colorFx.Parent = Lighting

-- ===== GEREEDSCHAP =====
local ws = workspace
local old = ws:FindFirstChild("Deco")
if old then old:Destroy() end
local deco = Instance.new("Folder"); deco.Name = "Deco"; deco.Parent = ws

local function part(props, parent)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.Metal
	for k, v in pairs(props) do p[k] = v end
	p.Parent = parent
	return p
end

-- ===== DEEL 2: LANTAARNS + FESTOEN-SLINGERS =====
local lampF = Instance.new("Model"); lampF.Name = "LampPosts"; lampF.Parent = deco
local function lampPost(x, z)
	local m = Instance.new("Model"); m.Name = "Lamp"; m.Parent = lampF
	part({Name="Base", Position=Vector3.new(x, 1.6, z), Size=Vector3.new(1.4, 1.2, 1.4), Color=Color3.fromRGB(35, 36, 44), CanCollide=true}, m)
	part({Name="Pole", Position=Vector3.new(x, 7.5, z), Size=Vector3.new(0.5, 11, 0.5), Color=Color3.fromRGB(48, 50, 60), CanCollide=true}, m)
	part({Name="Collar", Position=Vector3.new(x, 12.6, z), Size=Vector3.new(0.9, 0.3, 0.9), Color=Color3.fromRGB(35, 36, 44)}, m)
	local head = part({Name="Head", Position=Vector3.new(x, 13.4, z), Size=Vector3.new(1.3, 1.5, 1.3), Color=Color3.fromRGB(255, 228, 170), Material=Enum.Material.Neon}, m)
	part({Name="Cap", Position=Vector3.new(x, 14.4, z), Size=Vector3.new(1.6, 0.4, 1.6), Color=Color3.fromRGB(35, 36, 44)}, m)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 214, 150); light.Range = 30; light.Brightness = 1.9; light.Shadows = true
	light.Parent = head
end
lampPost(-22, -18); lampPost(22, -18); lampPost(-22, 46); lampPost(22, 46)

local festF = Instance.new("Model"); festF.Name = "Festoons"; festF.Parent = deco
local BULB_COLORS = { Color3.fromRGB(255, 214, 150), Color3.fromRGB(120, 220, 255), Color3.fromRGB(255, 130, 220) }
local function festoon(fromPos, toPos, sag, bulbCount)
	local prev = nil
	for i = 0, bulbCount do
		local t = i / bulbCount
		local pos = fromPos:Lerp(toPos, t) - Vector3.new(0, sag * 4 * t * (1 - t), 0)
		if prev then
			local mid = (prev + pos) / 2
			local wire = part({Name="Wire", Size=Vector3.new(0.07, 0.07, (pos - prev).Magnitude), Color=Color3.fromRGB(25, 25, 30), Material=Enum.Material.SmoothPlastic}, festF)
			wire.CFrame = CFrame.lookAt(mid, pos)
		end
		if i > 0 and i < bulbCount then
			part({Name="Bulb", Shape=Enum.PartType.Ball, Position=pos - Vector3.new(0, 0.28, 0),
				Size=Vector3.new(0.45, 0.45, 0.45), Color=BULB_COLORS[(i % #BULB_COLORS) + 1], Material=Enum.Material.Neon}, festF)
		end
		prev = pos
	end
end
festoon(Vector3.new(-45, 15, -12), Vector3.new(45, 15, -4), 2.5, 26)
festoon(Vector3.new(-45, 15.5, 18), Vector3.new(45, 15.5, 26), 2.8, 26)
festoon(Vector3.new(-22, 14.6, -18), Vector3.new(-22, 14.6, 46), 2.2, 20)
festoon(Vector3.new(22, 14.6, -18), Vector3.new(22, 14.6, 46), 2.2, 20)

-- ===== DEEL 3: VLOER, MUREN, MEUBILAIR =====
local pathF = Instance.new("Model"); pathF.Name = "NeonPath"; pathF.Parent = deco
for _, x in ipairs({ -6.5, 6.5 }) do
	local z = -30
	while z < 58 do
		part({Name="PathStrip", Position=Vector3.new(x, 1.06, z), Size=Vector3.new(0.35, 0.06, 3.2),
			Color=Color3.fromRGB(90, 200, 255), Material=Enum.Material.Neon}, pathF)
		z += 6
	end
end

local padF = Instance.new("Model"); padF.Name = "SpawnPad"; padF.Parent = deco
local function ring(radius, thickness, height, ringColor, material)
	for i = 0, 19 do
		local seg = part({Name="RingSeg", Size=Vector3.new(thickness, height, radius * 2 * math.sin(math.rad(9)) + 0.25),
			Color=ringColor, Material=material or Enum.Material.SmoothPlastic}, padF)
		seg.CFrame = CFrame.new(Vector3.new(0, 1.05, -38)) * CFrame.Angles(0, math.rad(i * 18), 0) * CFrame.new(radius, 0, 0)
	end
end
ring(5, 0.4, 0.06, Color3.fromRGB(90, 200, 255), Enum.Material.Neon)
ring(7.5, 0.7, 0.05, Color3.fromRGB(60, 62, 78))
ring(9.5, 0.4, 0.06, Color3.fromRGB(180, 120, 255), Enum.Material.Neon)

local wallF = Instance.new("Model"); wallF.Name = "WallDressing"; wallF.Parent = deco
local PILASTER = Color3.fromRGB(92, 94, 110)
for _, side in ipairs({ -1, 1 }) do
	local x = side * 44.4
	for z = -40, 60, 14 do
		part({Name="Pilaster", Position=Vector3.new(x, 9, z), Size=Vector3.new(1.2, 16, 2.6), Color=PILASTER, Material=Enum.Material.Concrete, CanCollide=true}, wallF)
		part({Name="PilasterGlow", Position=Vector3.new(x - side * 0.75, 9, z), Size=Vector3.new(0.15, 12, 0.5),
			Color=Color3.fromRGB(140, 110, 255), Material=Enum.Material.Neon}, wallF)
	end
	part({Name="TopLine", Position=Vector3.new(side * 44.7, 20.4, 10), Size=Vector3.new(0.3, 0.35, 108),
		Color=Color3.fromRGB(230, 90, 200), Material=Enum.Material.Neon}, wallF)
end
for x = -38, 38, 14 do
	if math.abs(x) > 16 then
		part({Name="Pilaster", Position=Vector3.new(x, 9, -44.4), Size=Vector3.new(2.6, 16, 1.2), Color=PILASTER, Material=Enum.Material.Concrete, CanCollide=true}, wallF)
	end
end
part({Name="TopLineN", Position=Vector3.new(0, 20.4, -44.7), Size=Vector3.new(88, 0.35, 0.3),
	Color=Color3.fromRGB(230, 90, 200), Material=Enum.Material.Neon}, wallF)

local propF = Instance.new("Model"); propF.Name = "StreetProps"; propF.Parent = deco
local function bench(x, z, rotY)
	local m = Instance.new("Model"); m.Name = "Bench"; m.Parent = propF
	local cf = CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(rotY), 0)
	local seat = part({Name="Seat", Size=Vector3.new(6, 0.4, 1.8), Color=Color3.fromRGB(120, 82, 58), Material=Enum.Material.WoodPlanks, CanCollide=true}, m)
	seat.CFrame = cf * CFrame.new(0, 2.2, 0)
	local back = part({Name="Back", Size=Vector3.new(6, 1.6, 0.35), Color=Color3.fromRGB(120, 82, 58), Material=Enum.Material.WoodPlanks, CanCollide=true}, m)
	back.CFrame = cf * CFrame.new(0, 3.2, 0.8) * CFrame.Angles(math.rad(-8), 0, 0)
	for _, dx in ipairs({ -2.5, 2.5 }) do
		local leg = part({Name="Leg", Size=Vector3.new(0.4, 2, 1.6), Color=Color3.fromRGB(40, 42, 50), CanCollide=true}, m)
		leg.CFrame = cf * CFrame.new(dx, 1.1, 0)
	end
end
bench(-14, -24, 180); bench(14, -24, 180); bench(-14, 18, 0); bench(14, 18, 0)

local function trashcan(x, z)
	local m = Instance.new("Model"); m.Name = "TrashCan"; m.Parent = propF
	local body = part({Name="Body", Shape=Enum.PartType.Cylinder, Size=Vector3.new(2.6, 1.6, 1.6),
		Color=Color3.fromRGB(200, 200, 205), CanCollide=true}, m)
	body.CFrame = CFrame.new(x, 2.3, z) * CFrame.Angles(0, 0, math.rad(90))
	local lid = part({Name="Lid", Shape=Enum.PartType.Cylinder, Size=Vector3.new(0.4, 1.8, 1.8),
		Color=Color3.fromRGB(200, 60, 60), Material=Enum.Material.SmoothPlastic, CanCollide=true}, m)
	lid.CFrame = CFrame.new(x, 3.8, z) * CFrame.Angles(0, 0, math.rad(90))
end
trashcan(-25, -2); trashcan(25, -2); trashcan(-25, 40); trashcan(25, 40)

-- ===== DEEL 4: WINKEL-AANKLEDING =====
local shopF = Instance.new("Model"); shopF.Name = "ShopDressing"; shopF.Parent = deco
local SHOP_ACCENTS = {
	west = { Color3.fromRGB(120, 220, 255), Color3.fromRGB(255, 170, 80), Color3.fromRGB(255, 130, 220) },
	east = { Color3.fromRGB(255, 120, 120), Color3.fromRGB(140, 110, 255), Color3.fromRGB(120, 255, 170) },
}
local ITEM_COLORS = {
	Color3.fromRGB(200, 90, 90), Color3.fromRGB(90, 160, 200), Color3.fromRGB(220, 190, 90),
	Color3.fromRGB(120, 190, 120), Color3.fromRGB(190, 120, 200), Color3.fromRGB(230, 230, 235),
}
local function dressShop(side, index, centerZ)
	local sgn = (side == "west") and 1 or -1
	local backX = (side == "west") and -44.2 or 44.2
	local frontX = (side == "west") and -34.6 or 34.6
	local accent = SHOP_ACCENTS[side][index]
	local m = Instance.new("Model"); m.Name = "Dress_" .. side .. index; m.Parent = shopF
	for i = 0, 4 do
		local slat = part({Name="Awning", Size=Vector3.new(4.6, 0.25, 3.4),
			Color=(i % 2 == 0) and accent or Color3.fromRGB(235, 232, 225), Material=Enum.Material.Fabric}, m)
		slat.CFrame = CFrame.new(frontX + sgn * 1.2, 12.4, centerZ - 6.4 + i * 3.2) * CFrame.Angles(0, 0, sgn * math.rad(-18))
	end
	for shelfIndex, shelfY in ipairs({ 6.2, 9.0 }) do
		part({Name="Shelf", Position=Vector3.new(backX + sgn * 0.7, shelfY, centerZ), Size=Vector3.new(1.2, 0.25, 12),
			Color=Color3.fromRGB(70, 60, 52), Material=Enum.Material.Wood}, m)
		for slot = 0, 4 do
			local itemColor = ITEM_COLORS[(slot + shelfIndex + index) % #ITEM_COLORS + 1]
			local isCan = (slot + shelfIndex) % 2 == 0
			local item = part({Name="Item", Color=itemColor,
				Size=isCan and Vector3.new(0.7, 1.1, 0.7) or Vector3.new(1.1, 0.9, 0.8),
				Material=isCan and Enum.Material.Metal or Enum.Material.SmoothPlastic}, m)
			item.CFrame = CFrame.new(backX + sgn * 0.7, shelfY + 0.7, centerZ - 4.4 + slot * 2.2)
			if isCan then
				item.Shape = Enum.PartType.Cylinder
				item.CFrame = item.CFrame * CFrame.Angles(0, 0, math.rad(90))
			end
		end
	end
	part({Name="Menu", Position=Vector3.new(backX + sgn * 0.4, 11.2, centerZ), Size=Vector3.new(0.3, 2.2, 9), Color=Color3.fromRGB(22, 22, 30), Material=Enum.Material.SmoothPlastic}, m)
	for line = 0, 2 do
		part({Name="MenuLine", Position=Vector3.new(backX + sgn * 0.6, 11.8 - line * 0.6, centerZ - 1 + line * 0.4),
			Size=Vector3.new(0.05, 0.18, 5.5 - line), Color=(line == 0) and accent or Color3.fromRGB(180, 180, 190), Material=Enum.Material.Neon}, m)
	end
	local counterX = (side == "west") and -37 or 37
	part({Name="Register", Position=Vector3.new(counterX, 5.1, centerZ - 3.5), Size=Vector3.new(1, 1.1, 1.3), Color=Color3.fromRGB(38, 38, 46)}, m)
	part({Name="RegisterScreen", Position=Vector3.new(counterX - sgn * 0.2, 5.35, centerZ - 3.5), Size=Vector3.new(0.55, 0.5, 0.08), Color=accent, Material=Enum.Material.Neon}, m)
	for cup = 0, 1 do
		local c = part({Name="Cup", Shape=Enum.PartType.Cylinder, Size=Vector3.new(0.8, 0.55, 0.55), Color=Color3.fromRGB(235, 232, 225), Material=Enum.Material.SmoothPlastic}, m)
		c.CFrame = CFrame.new(counterX, 4.9, centerZ + 2 + cup * 1.1) * CFrame.Angles(0, 0, math.rad(90))
	end
	local anchor = part({Name="LightAnchor", Position=Vector3.new((backX + frontX) / 2, 11.5, centerZ), Size=Vector3.new(0.2, 0.2, 0.2), Transparency=1}, m)
	local glow = Instance.new("PointLight")
	glow.Color = Color3.fromRGB(255, 225, 180); glow.Range = 13; glow.Brightness = 0.9
	glow.Parent = anchor
end
for i, z in ipairs({ -20, 10, 40 }) do
	dressShop("west", i, z)
	dressShop("east", i, z)
end

-- ===== DEEL 5: DE GROTE POORT =====
local archF = Instance.new("Model"); archF.Name = "ArchDressing"; archF.Parent = deco
local ARC_CENTER = Vector3.new(0, 20.5, -44)
local ARC_RADIUS = 13
for i = 0, 9 do
	local a1 = math.rad(i * 18)
	local a2 = math.rad((i + 1) * 18)
	local p1 = ARC_CENTER + Vector3.new(math.cos(a1) * ARC_RADIUS, math.sin(a1) * ARC_RADIUS, 0)
	local p2 = ARC_CENTER + Vector3.new(math.cos(a2) * ARC_RADIUS, math.sin(a2) * ARC_RADIUS, 0)
	local seg = part({Name="ArcSeg", Size=Vector3.new(0.8, 0.8, (p2 - p1).Magnitude + 0.3),
		Color=Color3.fromRGB(230, 90, 200), Material=Enum.Material.Neon}, archF)
	seg.CFrame = CFrame.lookAt((p1 + p2) / 2, p2)
	local q1 = ARC_CENTER + Vector3.new(math.cos(a1) * (ARC_RADIUS - 1.6), math.sin(a1) * (ARC_RADIUS - 1.6), 0)
	local q2 = ARC_CENTER + Vector3.new(math.cos(a2) * (ARC_RADIUS - 1.6), math.sin(a2) * (ARC_RADIUS - 1.6), 0)
	local seg2 = part({Name="ArcSegInner", Size=Vector3.new(0.4, 0.4, (q2 - q1).Magnitude + 0.2),
		Color=Color3.fromRGB(120, 220, 255), Material=Enum.Material.Neon}, archF)
	seg2.CFrame = CFrame.lookAt((q1 + q2) / 2, q2)
end
local starCF = CFrame.new(0, 36.6, -44)
part({Name="StarV", Size=Vector3.new(0.9, 6.5, 0.9), Color=Color3.fromRGB(255, 240, 200), Material=Enum.Material.Neon}, archF).CFrame = starCF
part({Name="StarH", Size=Vector3.new(6.5, 0.9, 0.9), Color=Color3.fromRGB(255, 240, 200), Material=Enum.Material.Neon}, archF).CFrame = starCF
part({Name="StarD1", Size=Vector3.new(0.55, 4, 0.55), Color=Color3.fromRGB(230, 90, 200), Material=Enum.Material.Neon}, archF).CFrame = starCF * CFrame.Angles(0, 0, math.rad(45))
part({Name="StarD2", Size=Vector3.new(0.55, 4, 0.55), Color=Color3.fromRGB(230, 90, 200), Material=Enum.Material.Neon}, archF).CFrame = starCF * CFrame.Angles(0, 0, math.rad(-45))
local starLight = Instance.new("PointLight")
starLight.Color = Color3.fromRGB(255, 220, 240); starLight.Range = 20; starLight.Brightness = 1.2
starLight.Parent = archF.StarV
part({Name="Saturn", Shape=Enum.PartType.Ball, Position=Vector3.new(12, 21.5, -44),
	Size=Vector3.new(4.2, 4.2, 4.2), Color=Color3.fromRGB(225, 180, 120), Material=Enum.Material.Sand}, archF)
local satRing = part({Name="SaturnRing", Shape=Enum.PartType.Cylinder, Size=Vector3.new(0.18, 7.4, 7.4),
	Color=Color3.fromRGB(240, 210, 160), Material=Enum.Material.Neon}, archF)
satRing.CFrame = CFrame.new(12, 21.5, -44) * CFrame.Angles(0, math.rad(15), math.rad(75))
local moon = part({Name="Moon", Shape=Enum.PartType.Ball, Position=Vector3.new(-12, 20.8, -44),
	Size=Vector3.new(2.6, 2.6, 2.6), Color=Color3.fromRGB(200, 200, 215), Material=Enum.Material.Slate}, archF)
local moonGlow = Instance.new("PointLight")
moonGlow.Color = Color3.fromRGB(180, 190, 255); moonGlow.Range = 10; moonGlow.Brightness = 0.6
moonGlow.Parent = moon
for _, x in ipairs({ -9, 9 }) do
	local spot = part({Name="UpLight", Position=Vector3.new(x, 1.3, -41.5), Size=Vector3.new(0.8, 0.5, 0.8), Color=Color3.fromRGB(40, 40, 48)}, archF)
	local sl = Instance.new("SpotLight")
	sl.Face = Enum.NormalId.Top; sl.Angle = 40; sl.Range = 26; sl.Brightness = 2.2
	sl.Color = Color3.fromRGB(220, 150, 255)
	sl.Parent = spot
end

-- ===== DEEL 6: REUZENRAD =====
local wheel = Instance.new("Model"); wheel.Name = "FerrisWheel"; wheel.Parent = deco
wheel:SetAttribute("SpinSpeed", 6)
local HUB = Vector3.new(0, 30, -82)
local RADIUS = 17
local hub = part({Name="Hub", Shape=Enum.PartType.Ball, Position=HUB, Size=Vector3.new(3.2, 3.2, 3.2),
	Color=Color3.fromRGB(240, 210, 120), Material=Enum.Material.Neon}, wheel)
wheel.PrimaryPart = hub
local spinner = Instance.new("Model"); spinner.Name = "Spinner"; spinner.Parent = wheel
local spinnerCore = part({Name="Core", Position=HUB, Size=Vector3.new(0.6, 0.6, 0.6), Transparency=1}, spinner)
spinner.PrimaryPart = spinnerCore
for i = 0, 5 do
	local spoke = part({Name="Spoke", Size=Vector3.new(0.5, RADIUS * 2, 0.5), Color=Color3.fromRGB(70, 72, 86)}, spinner)
	spoke.CFrame = CFrame.new(HUB) * CFrame.Angles(0, 0, math.rad(i * 30))
end
local RIM_COLORS = { Color3.fromRGB(230, 90, 200), Color3.fromRGB(120, 220, 255) }
for i = 0, 23 do
	local a1 = math.rad(i * 15)
	local a2 = math.rad((i + 1) * 15)
	local p1 = HUB + Vector3.new(math.cos(a1) * RADIUS, math.sin(a1) * RADIUS, 0)
	local p2 = HUB + Vector3.new(math.cos(a2) * RADIUS, math.sin(a2) * RADIUS, 0)
	local seg = part({Name="Rim", Size=Vector3.new(0.6, 0.6, (p2 - p1).Magnitude + 0.2),
		Color=RIM_COLORS[(i % 2) + 1], Material=Enum.Material.Neon}, spinner)
	seg.CFrame = CFrame.lookAt((p1 + p2) / 2, p2)
end
local CABIN_COLORS = { Color3.fromRGB(220, 80, 80), Color3.fromRGB(90, 160, 220), Color3.fromRGB(240, 200, 90), Color3.fromRGB(120, 200, 130) }
for i = 0, 7 do
	local a = math.rad(i * 45)
	local pos = HUB + Vector3.new(math.cos(a) * (RADIUS - 0.5), math.sin(a) * (RADIUS - 0.5), 0)
	part({Name="Cabin", Position=pos - Vector3.new(0, 1.6, 0), Size=Vector3.new(2.6, 2.4, 2.2),
		Color=CABIN_COLORS[(i % 4) + 1], Material=Enum.Material.SmoothPlastic}, spinner)
	part({Name="CabinRoof", Position=pos - Vector3.new(0, 0.2, 0), Size=Vector3.new(2.9, 0.3, 2.5),
		Color=Color3.fromRGB(40, 42, 50)}, spinner)
end
for _, side in ipairs({ -1, 1 }) do
	local leg = part({Name="Leg", Size=Vector3.new(1.2, 33, 1.2), Color=Color3.fromRGB(60, 62, 74)}, wheel)
	leg.CFrame = CFrame.new(HUB.X + side * 7, 15, HUB.Z + 1.5) * CFrame.Angles(0, 0, side * math.rad(-12))
	local leg2 = part({Name="Leg2", Size=Vector3.new(1.2, 33, 1.2), Color=Color3.fromRGB(60, 62, 74)}, wheel)
	leg2.CFrame = CFrame.new(HUB.X + side * 7, 15, HUB.Z - 1.5) * CFrame.Angles(0, 0, side * math.rad(-12))
end
part({Name="CrossBeam", Position=Vector3.new(0, 12, HUB.Z), Size=Vector3.new(15, 0.8, 0.8), Color=Color3.fromRGB(60, 62, 74)}, wheel)

-- ===== DEEL 7: RAKET-TOREN, PLANETEN, BALLONNEN =====
local rocketF = Instance.new("Model"); rocketF.Name = "RocketTower"; rocketF.Parent = deco
local RX, RZ = 72, -8
for _, dx in ipairs({ -2.5, 2.5 }) do
	for _, dz in ipairs({ -2.5, 2.5 }) do
		part({Name="TowerLeg", Position=Vector3.new(RX + dx, 11, RZ + dz), Size=Vector3.new(0.7, 22, 0.7), Color=Color3.fromRGB(140, 60, 50)}, rocketF)
	end
end
for h = 5, 20, 5 do
	part({Name="TowerBrace", Position=Vector3.new(RX, h, RZ), Size=Vector3.new(6.4, 0.5, 0.5), Color=Color3.fromRGB(140, 60, 50)}, rocketF)
	part({Name="TowerBrace2", Position=Vector3.new(RX, h, RZ), Size=Vector3.new(0.5, 0.5, 6.4), Color=Color3.fromRGB(140, 60, 50)}, rocketF)
end
local BODY_X = RX - 7
for _, band in ipairs({ {4, Color3.fromRGB(235, 235, 240)}, {10, Color3.fromRGB(210, 60, 60)}, {16, Color3.fromRGB(235, 235, 240)} }) do
	local b = part({Name="RocketBand", Shape=Enum.PartType.Cylinder, Size=Vector3.new(6, 6.5, 6.5), Color=band[2], Material=Enum.Material.SmoothPlastic}, rocketF)
	b.CFrame = CFrame.new(BODY_X, band[1], RZ) * CFrame.Angles(0, 0, math.rad(90))
end
local nose1 = part({Name="Nose1", Shape=Enum.PartType.Cylinder, Size=Vector3.new(2.6, 5, 5), Color=Color3.fromRGB(210, 60, 60), Material=Enum.Material.SmoothPlastic}, rocketF)
nose1.CFrame = CFrame.new(BODY_X, 20.3, RZ) * CFrame.Angles(0, 0, math.rad(90))
local nose2 = part({Name="Nose2", Shape=Enum.PartType.Cylinder, Size=Vector3.new(2.2, 3.2, 3.2), Color=Color3.fromRGB(210, 60, 60), Material=Enum.Material.SmoothPlastic}, rocketF)
nose2.CFrame = CFrame.new(BODY_X, 22.6, RZ) * CFrame.Angles(0, 0, math.rad(90))
part({Name="NoseTip", Shape=Enum.PartType.Ball, Position=Vector3.new(BODY_X, 24.6, RZ), Size=Vector3.new(1.8, 1.8, 1.8), Color=Color3.fromRGB(235, 235, 240), Material=Enum.Material.SmoothPlastic}, rocketF)
local beacon = part({Name="Beacon", Shape=Enum.PartType.Ball, Position=Vector3.new(BODY_X, 25.8, RZ), Size=Vector3.new(0.9, 0.9, 0.9),
	Color=Color3.fromRGB(255, 60, 60), Material=Enum.Material.Neon}, rocketF)
beacon:SetAttribute("Blink", true)
local beaconLight = Instance.new("PointLight"); beaconLight.Color = Color3.fromRGB(255, 80, 80); beaconLight.Range = 14; beaconLight.Brightness = 1.4; beaconLight.Parent = beacon
for i = 0, 3 do
	local fin = part({Name="Fin", Size=Vector3.new(0.5, 5, 2.6), Color=Color3.fromRGB(210, 60, 60)}, rocketF)
	fin.CFrame = CFrame.new(BODY_X, 3, RZ) * CFrame.Angles(0, math.rad(i * 90), 0) * CFrame.new(0, 0, 3.8) * CFrame.Angles(math.rad(-14), 0, 0)
end
local rSpot = part({Name="RocketSpot", Position=Vector3.new(RX - 14, 1, RZ + 8), Size=Vector3.new(1, 0.6, 1), Color=Color3.fromRGB(40, 40, 48)}, rocketF)
local rsl = Instance.new("SpotLight"); rsl.Face = Enum.NormalId.Top; rsl.Angle = 35; rsl.Range = 34; rsl.Brightness = 1.6
rsl.Color = Color3.fromRGB(255, 220, 190); rsl.Parent = rSpot

local planetF = Instance.new("Model"); planetF.Name = "Planets"; planetF.Parent = deco
local function planetPole(x, z, height, size, planetColor, withRing)
	part({Name="Pole", Position=Vector3.new(x, height / 2, z), Size=Vector3.new(0.5, height, 0.5), Color=Color3.fromRGB(50, 52, 62)}, planetF)
	local planet = part({Name="Planet", Shape=Enum.PartType.Ball, Position=Vector3.new(x, height + size / 2, z),
		Size=Vector3.new(size, size, size), Color=planetColor, Material=Enum.Material.SmoothPlastic}, planetF)
	local glow = Instance.new("PointLight"); glow.Color = planetColor; glow.Range = size * 3; glow.Brightness = 0.7; glow.Parent = planet
	if withRing then
		local pring = part({Name="Ring", Shape=Enum.PartType.Cylinder, Size=Vector3.new(0.2, size * 1.9, size * 1.9),
			Color=Color3.fromRGB(240, 210, 160), Material=Enum.Material.Neon}, planetF)
		pring.CFrame = CFrame.new(x, height + size / 2, z) * CFrame.Angles(0, math.rad(20), math.rad(72))
	end
end
planetPole(-68, -25, 20, 9, Color3.fromRGB(200, 140, 90), true)
planetPole(-74, 8, 14, 5.5, Color3.fromRGB(120, 160, 230), false)
planetPole(-64, 30, 24, 6.5, Color3.fromRGB(190, 120, 200), false)

local BALLOON_COLORS = { Color3.fromRGB(220, 80, 80), Color3.fromRGB(90, 160, 220), Color3.fromRGB(240, 200, 90), Color3.fromRGB(230, 90, 200), Color3.fromRGB(120, 200, 130) }
local function balloonCluster(name, anchorPos)
	local m = Instance.new("Model"); m.Name = name; m.Parent = deco
	m:SetAttribute("Bob", true)
	local core = part({Name="Core", Position=anchorPos, Size=Vector3.new(0.3, 0.3, 0.3), Transparency=1}, m)
	m.PrimaryPart = core
	local offsets = {
		Vector3.new(0, 5.5, 0), Vector3.new(1.1, 4.9, 0.5), Vector3.new(-1, 5.1, -0.4),
		Vector3.new(0.5, 4.4, -0.9), Vector3.new(-0.6, 4.5, 0.9),
	}
	for i, off in ipairs(offsets) do
		local bpos = anchorPos + off
		part({Name="Balloon", Shape=Enum.PartType.Ball, Position=bpos, Size=Vector3.new(1.7, 2, 1.7),
			Color=BALLOON_COLORS[i], Material=Enum.Material.SmoothPlastic, Reflectance=0.08}, m)
		local wire = part({Name="String", Size=Vector3.new(0.05, 0.05, off.Magnitude), Color=Color3.fromRGB(220, 220, 225), Material=Enum.Material.SmoothPlastic}, m)
		wire.CFrame = CFrame.lookAt(anchorPos + off / 2, bpos)
	end
end
balloonCluster("Balloons1", Vector3.new(-22, 2, -18))
balloonCluster("Balloons2", Vector3.new(22, 2, 46))
balloonCluster("Balloons3", Vector3.new(8, 5.5, 65))

-- ===== DEEL 8: NACHT-FIXES (leesbaar bord + verlichte plantenbakken) =====
local plaza = ws.Map.Zones.SpawnPlaza
local archBeam = plaza:FindFirstChild("ArchBeam")
if archBeam then
	archBeam.Color = Color3.fromRGB(168, 62, 148)
	for _, sg in ipairs(archBeam:GetChildren()) do
		if sg:IsA("SurfaceGui") then
			local tl = sg:FindFirstChildOfClass("TextLabel")
			if tl then tl.TextColor3 = Color3.fromRGB(10, 8, 14) end
		end
	end
end
local function lightPlanter(model)
	if not model then return end
	for _, child in ipairs(model:GetChildren()) do
		if child.Name == "PlanterBase" then
			local rim = Instance.new("Part")
			rim.Anchored = true; rim.CanCollide = false; rim.CanQuery = false
			rim.Material = Enum.Material.Neon
			rim.Color = Color3.fromRGB(120, 220, 255)
			rim.Size = Vector3.new(child.Size.X + 0.15, 0.22, child.Size.Z + 0.15)
			rim.Position = child.Position + Vector3.new(0, child.Size.Y / 2 + 0.08, 0)
			rim.Name = "PlanterRim"
			rim.Parent = model
		elseif child.Name == "Hedge" or child.Name == "HedgeTop" then
			child.Color = Color3.fromRGB(52, 88, 58)
			local glow = Instance.new("PointLight")
			glow.Color = Color3.fromRGB(150, 220, 170); glow.Range = 7; glow.Brightness = 0.5
			glow.Parent = child
		end
	end
end
lightPlanter(plaza:FindFirstChild("Planter_Hedge_Mid"))
lightPlanter(plaza:FindFirstChild("ParkMapDisplay"))
local door = ws.Map.Doors:FindFirstChild("Door_MainStreet")
if door then
	lightPlanter(door)
	lightPlanter(door:FindFirstChild("Planter_Hedge_Gate"))
end

print("[Polish] Fase 11-decor herbouwd: nacht, licht, park, rad, raket — Spaceland leeft")
