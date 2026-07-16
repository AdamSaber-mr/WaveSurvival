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
		-- oostmuur: pilaar bij z=44 wijkt uit naar z=48 (daar zit een spawn-deur)
		local zz = (side == 1 and z == 44) and 48 or z
		part({Name="Pilaster", Position=Vector3.new(x, 9, zz), Size=Vector3.new(1.2, 16, 2.6), Color=PILASTER, Material=Enum.Material.Concrete, CanCollide=true}, wallF)
		part({Name="PilasterGlow", Position=Vector3.new(x - side * 0.75, 9, zz), Size=Vector3.new(0.15, 12, 0.5),
			Color=Color3.fromRGB(140, 110, 255), Material=Enum.Material.Neon}, wallF)
	end
	part({Name="TopLine", Position=Vector3.new(side * 44.7, 20.4, 10), Size=Vector3.new(0.3, 0.35, 108),
		Color=Color3.fromRGB(230, 90, 200), Material=Enum.Material.Neon}, wallF)
end
for x = -38, 38, 14 do
	if math.abs(x) > 16 then
		-- x=-38 wijkt uit naar -30 (daar zit spawn-deur 1)
		local xx = (x == -38) and -30 or x
		part({Name="Pilaster", Position=Vector3.new(xx, 9, -44.4), Size=Vector3.new(2.6, 16, 1.2), Color=PILASTER, Material=Enum.Material.Concrete, CanCollide=true}, wallF)
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


-- ===== DEEL 9: SPAWN-DEUREN (kwaliteitsslag) =====
do
	local doorsF = Instance.new("Model"); doorsF.Name = "SpawnDoors"; doorsF.Parent = deco
	local FRAME_C = Color3.fromRGB(52, 50, 58)
	local DARKNESS = Color3.fromRGB(8, 8, 12)
	local PLANK = Color3.fromRGB(96, 66, 44)
	local function spawnDoor(cf, wide)
		local m = Instance.new("Model"); m.Name = "SpawnDoor"; m.Parent = doorsF
		local w = wide and 7 or 5.5
		local dark = part({Name="Darkness", Size=Vector3.new(w, 9, 0.4), Color=DARKNESS, Material=Enum.Material.SmoothPlastic}, m)
		dark.CFrame = cf * CFrame.new(0, 4.5, -0.2)
		for _, dx in ipairs({ -(w/2 + 0.4), w/2 + 0.4 }) do
			part({Name="Post", Size=Vector3.new(0.8, 10, 1), Color=FRAME_C, CanCollide=true, Material=Enum.Material.Concrete}, m).CFrame = cf * CFrame.new(dx, 5, -0.2)
		end
		part({Name="Lintel", Size=Vector3.new(w + 2.4, 0.9, 1), Color=FRAME_C, CanCollide=true, Material=Enum.Material.Concrete}, m).CFrame = cf * CFrame.new(0, 10.2, -0.2)
		local hazard = part({Name="Hazard", Size=Vector3.new(w + 2.4, 0.7, 0.2), Color=Color3.fromRGB(230, 190, 60), Material=Enum.Material.SmoothPlastic}, m)
		hazard.CFrame = cf * CFrame.new(0, 9.4, -0.75)
		local sg = Instance.new("SurfaceGui"); sg.Face = Enum.NormalId.Front; sg.Parent = hazard
		local fr = Instance.new("Frame"); fr.Size = UDim2.new(1, 0, 1, 0); fr.BorderSizePixel = 0
		fr.BackgroundColor3 = Color3.fromRGB(230, 190, 60); fr.Parent = sg
		local grad = Instance.new("UIGradient")
		local Y, B = Color3.fromRGB(230, 190, 60), Color3.fromRGB(25, 25, 28)
		grad.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0.000, Y), ColorSequenceKeypoint.new(0.124, Y),
			ColorSequenceKeypoint.new(0.126, B), ColorSequenceKeypoint.new(0.249, B),
			ColorSequenceKeypoint.new(0.251, Y), ColorSequenceKeypoint.new(0.374, Y),
			ColorSequenceKeypoint.new(0.376, B), ColorSequenceKeypoint.new(0.499, B),
			ColorSequenceKeypoint.new(0.501, Y), ColorSequenceKeypoint.new(0.624, Y),
			ColorSequenceKeypoint.new(0.626, B), ColorSequenceKeypoint.new(0.749, B),
			ColorSequenceKeypoint.new(0.751, Y), ColorSequenceKeypoint.new(0.874, Y),
			ColorSequenceKeypoint.new(0.876, B), ColorSequenceKeypoint.new(1.000, B),
		})
		grad.Rotation = 25
		grad.Parent = fr
		local plank1 = part({Name="Plank", Size=Vector3.new(w + 1.6, 0.7, 0.25), Color=PLANK, Material=Enum.Material.WoodPlanks}, m)
		plank1.CFrame = cf * CFrame.new(0.3, 6.4, -0.65) * CFrame.Angles(0, 0, math.rad(-9))
		local plank2 = part({Name="Plank", Size=Vector3.new(w + 0.8, 0.7, 0.25), Color=PLANK, Material=Enum.Material.WoodPlanks}, m)
		plank2.CFrame = cf * CFrame.new(-0.4, 3.1, -0.65) * CFrame.Angles(0, 0, math.rad(14))
		local sign = part({Name="Sign", Size=Vector3.new(2.6, 1, 0.15), Color=Color3.fromRGB(200, 195, 185), Material=Enum.Material.SmoothPlastic}, m)
		sign.CFrame = cf * CFrame.new(0.2, 6.45, -0.88) * CFrame.Angles(0, 0, math.rad(-9))
		local ssg = Instance.new("SurfaceGui"); ssg.Face = Enum.NormalId.Front; ssg.Parent = sign
		local stl = Instance.new("TextLabel"); stl.Size = UDim2.new(1, 0, 1, 0); stl.BackgroundTransparency = 1
		stl.Text = "KEEP OUT"; stl.TextColor3 = Color3.fromRGB(160, 30, 30); stl.TextScaled = true; stl.Font = Enum.Font.SpecialElite
		stl.Parent = ssg
		local warnLight = part({Name="WarnLight", Shape=Enum.PartType.Ball, Size=Vector3.new(0.7, 0.7, 0.7),
			Color=Color3.fromRGB(255, 60, 60), Material=Enum.Material.Neon}, m)
		warnLight.CFrame = cf * CFrame.new(0, 10.9, -0.5)
		warnLight:SetAttribute("Blink", true)
		local wl = Instance.new("PointLight"); wl.Color = Color3.fromRGB(255, 70, 70); wl.Range = 9; wl.Brightness = 1.1; wl.Parent = warnLight
		local mist = Instance.new("ParticleEmitter")
		mist.Color = ColorSequence.new(Color3.fromRGB(120, 180, 120))
		mist.Lifetime = NumberRange.new(2, 3.5)
		mist.Rate = 3
		mist.Speed = NumberRange.new(0.6, 1.4)
		mist.SpreadAngle = Vector2.new(25, 15)
		mist.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.4), NumberSequenceKeypoint.new(1, 3.4) })
		mist.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.82), NumberSequenceKeypoint.new(1, 1) })
		mist.Parent = dark
		local smear = part({Name="BloodSmear", Size=Vector3.new(2.6, 0.03, 4.2), Color=Color3.fromRGB(78, 16, 16), Material=Enum.Material.Slate}, m)
		smear.CFrame = cf * CFrame.new(0.4, 0.08, -2.6) * CFrame.Angles(0, math.rad(18), 0)
	end
	-- alle 4 kijken de plaza in (achtermuur = 180 graden gedraaid)
	spawnDoor(CFrame.new(-40, 1, -45) * CFrame.Angles(0, math.rad(180), 0), true)
	spawnDoor(CFrame.new(40, 1, -45) * CFrame.Angles(0, math.rad(180), 0), true)
	spawnDoor(CFrame.new(-45, 1, 10) * CFrame.Angles(0, math.rad(-90), 0), false)
	spawnDoor(CFrame.new(45, 1, 40) * CFrame.Angles(0, math.rad(90), 0), false)

	-- zombies zijn door de winkelschappen heen gebroken (deuren 3 en 4 zitten in winkels)
	local brng = Random.new(77)
	local function breakThrough(dressName, wallX, doorZ)
		local dress = deco.ShopDressing:FindFirstChild(dressName)
		if not dress then return end
		local inward = (wallX > 0) and -1 or 1
		for _, inst in ipairs(dress:GetChildren()) do
			if inst.Name == "Shelf" and math.abs(inst.Position.Z - doorZ) < 1 then
				local y = inst.Position.Y
				for _, dside in ipairs({ -1, 1 }) do
					local stub = inst:Clone()
					stub.Size = Vector3.new(inst.Size.X, inst.Size.Y, 2.3)
					stub.CFrame = CFrame.new(inst.Position.X, y, doorZ + dside * 4.85)
					stub.Parent = dress
				end
				local snapped = inst:Clone()
				snapped.Size = Vector3.new(inst.Size.X, inst.Size.Y, 1.6)
				snapped.CFrame = CFrame.new(inst.Position.X + inward * 0.3, y - 0.55, doorZ - 2.9)
					* CFrame.Angles(math.rad(-38), 0, math.rad(inward * 8))
				snapped.Parent = dress
				inst:Destroy()
			elseif inst.Name == "Item" and math.abs(inst.Position.Z - doorZ) < 3 then
				inst.CFrame = CFrame.new(
					inst.Position.X + inward * brng:NextNumber(1.5, 4),
					1 + inst.Size.Y / 2 - 0.25,
					inst.Position.Z + brng:NextNumber(-2.5, 2.5)
				) * CFrame.Angles(math.rad(brng:NextNumber(-100, 100)), math.rad(brng:NextNumber(0, 360)), math.rad(brng:NextNumber(-30, 30)))
			end
		end
	end
	breakThrough("Dress_west2", -43.5, 10)
	breakThrough("Dress_east3", 43.5, 40)

	-- ===== v2-detail per deur: puin, klauwsporen, vonk-kabel, bloedhanden, extra plank, scheuren =====
	local drng = Random.new(4242)
	local DOOR_CFS = {
		{ cf = CFrame.new(-40, 1, -45) * CFrame.Angles(0, math.rad(180), 0), wide = true },
		{ cf = CFrame.new(40, 1, -45) * CFrame.Angles(0, math.rad(180), 0), wide = true },
		{ cf = CFrame.new(-45, 1, 10) * CFrame.Angles(0, math.rad(-90), 0), wide = false },
		{ cf = CFrame.new(45, 1, 40) * CFrame.Angles(0, math.rad(90), 0), wide = false },
	}
	local doorModels = {}
	for _, child in ipairs(doorsF:GetChildren()) do table.insert(doorModels, child) end
	for i, info in ipairs(DOOR_CFS) do
		local m = doorModels[i]
		if not m then continue end
		local cf, w = info.cf, info.wide and 7 or 5.5
		for b = 1, 5 do
			local s = drng:NextNumber(0.5, 1.4)
			local chunk = part({Name="Rubble", Size=Vector3.new(s, s * drng:NextNumber(0.5, 0.8), s * drng:NextNumber(0.7, 1.2)),
				Color=Color3.fromRGB(drng:NextInteger(70, 95), drng:NextInteger(70, 95), drng:NextInteger(80, 105)),
				Material=Enum.Material.Concrete}, m)
			chunk.CFrame = cf * CFrame.new(drng:NextNumber(-w/2, w/2), 0.25 + s * 0.2, -drng:NextNumber(0.6, 2.4))
				* CFrame.Angles(math.rad(drng:NextNumber(-25, 25)), math.rad(drng:NextNumber(0, 360)), math.rad(drng:NextNumber(-25, 25)))
		end
		for _, sideX in ipairs({ -(w/2 + 1.6), w/2 + 1.6 }) do
			for c = 0, 2 do
				local scratch = part({Name="ClawMark", Size=Vector3.new(0.12, drng:NextNumber(1.6, 2.6), 0.06),
					Color=Color3.fromRGB(30, 30, 36), Material=Enum.Material.SmoothPlastic}, m)
				scratch.CFrame = cf * CFrame.new(sideX + c * 0.28, drng:NextNumber(3.5, 5.5), -0.56)
					* CFrame.Angles(0, 0, math.rad(14 + drng:NextNumber(-4, 4)))
			end
		end
		local cable1 = part({Name="Cable", Size=Vector3.new(0.09, 1.6, 0.09), Color=Color3.fromRGB(20, 20, 24), Material=Enum.Material.SmoothPlastic}, m)
		cable1.CFrame = cf * CFrame.new(w/2 - 0.8, 9.2, -0.55) * CFrame.Angles(0, 0, math.rad(12))
		local cable2 = part({Name="Cable", Size=Vector3.new(0.09, 1.1, 0.09), Color=Color3.fromRGB(20, 20, 24), Material=Enum.Material.SmoothPlastic}, m)
		cable2.CFrame = cf * CFrame.new(w/2 - 1.05, 8.05, -0.55) * CFrame.Angles(0, 0, math.rad(-24))
		local tip = part({Name="CableTip", Size=Vector3.new(0.14, 0.18, 0.14), Color=Color3.fromRGB(200, 170, 90)}, m)
		tip.CFrame = cf * CFrame.new(w/2 - 1.28, 7.6, -0.55)
		local sparks = Instance.new("ParticleEmitter")
		sparks.Color = ColorSequence.new(Color3.fromRGB(255, 220, 120), Color3.fromRGB(255, 140, 60))
		sparks.LightEmission = 1
		sparks.Lifetime = NumberRange.new(0.15, 0.45)
		sparks.Rate = 0 -- SceneryService laat hem knetteren via het Spark-attribute
		sparks.Speed = NumberRange.new(4, 9)
		sparks.SpreadAngle = Vector2.new(65, 65)
		sparks.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.12), NumberSequenceKeypoint.new(1, 0.02) })
		sparks.Acceleration = Vector3.new(0, -35, 0)
		sparks.Parent = tip
		tip:SetAttribute("Spark", true)
		for _, sideX in ipairs({ -(w/2 + 0.4), w/2 + 0.4 }) do
			if drng:NextNumber() < 0.85 then
				local hy = drng:NextNumber(2.6, 4.2)
				local palm = part({Name="BloodHand", Size=Vector3.new(0.42, 0.5, 0.05), Color=Color3.fromRGB(88, 18, 18), Material=Enum.Material.SmoothPlastic}, m)
				palm.CFrame = cf * CFrame.new(sideX, hy, -0.74) * CFrame.Angles(0, 0, math.rad(drng:NextNumber(-30, 30)))
				for f = 0, 3 do
					local finger = part({Name="BloodFinger", Size=Vector3.new(0.08, 0.22, 0.05), Color=Color3.fromRGB(88, 18, 18), Material=Enum.Material.SmoothPlastic}, m)
					finger.CFrame = palm.CFrame * CFrame.new(-0.15 + f * 0.1, 0.34, 0)
				end
			end
		end
		local plank3 = part({Name="Plank", Size=Vector3.new(w * 0.6, 0.55, 0.22), Color=Color3.fromRGB(88, 60, 40),
			Material=Enum.Material.WoodPlanks}, m)
		plank3.CFrame = cf * CFrame.new(w * 0.14, 1.3, -0.6) * CFrame.Angles(0, 0, math.rad(-22))
		for _, pl in ipairs(m:GetChildren()) do
			if pl.Name == "Plank" then
				for _, endX in ipairs({ -pl.Size.X/2 + 0.45, pl.Size.X/2 - 0.45 }) do
					local nail = part({Name="Nail", Shape=Enum.PartType.Cylinder, Size=Vector3.new(0.06, 0.16, 0.16),
						Color=Color3.fromRGB(120, 120, 128)}, m)
					nail.CFrame = pl.CFrame * CFrame.new(endX, 0, -0.14) * CFrame.Angles(0, math.rad(90), 0)
				end
			end
		end
		for c = 1, 3 do
			local sideX = (c % 2 == 0) and (w/2 + 1.1) or -(w/2 + 1.1)
			local crack = part({Name="WallCrack", Size=Vector3.new(0.08, drng:NextNumber(1.2, 2.4), 0.05),
				Color=Color3.fromRGB(34, 34, 42), Material=Enum.Material.SmoothPlastic}, m)
			crack.CFrame = cf * CFrame.new(sideX + drng:NextNumber(-0.4, 0.4), 8.6 + drng:NextNumber(0, 1.4), -0.56)
				* CFrame.Angles(0, 0, math.rad(drng:NextNumber(-30, 30)))
		end
	end
end

-- ===== DEEL 10: MAP-SLIJTAGE (kwaliteitsslag) =====
do
	local wearF = Instance.new("Model"); wearF.Name = "WearAndTear"; wearF.Parent = deco
	local wrng = Random.new(1337) -- vaste seed: herbouw geeft dezelfde slijtage
	part({Name="Skirt", Position=Vector3.new(-44.7, 1.5, 10), Size=Vector3.new(0.5, 1, 110), Color=Color3.fromRGB(38, 38, 46), Material=Enum.Material.Concrete}, wearF)
	part({Name="Skirt", Position=Vector3.new(44.7, 1.5, 10), Size=Vector3.new(0.5, 1, 110), Color=Color3.fromRGB(38, 38, 46), Material=Enum.Material.Concrete}, wearF)
	part({Name="Skirt", Position=Vector3.new(0, 1.5, -44.7), Size=Vector3.new(90, 1, 0.5), Color=Color3.fromRGB(38, 38, 46), Material=Enum.Material.Concrete}, wearF)
	for _, y in ipairs({ 7.5, 14.5 }) do
		part({Name="Seam", Position=Vector3.new(-44.85, y, 10), Size=Vector3.new(0.15, 0.18, 108), Color=Color3.fromRGB(52, 54, 66)}, wearF)
		part({Name="Seam", Position=Vector3.new(44.85, y, 10), Size=Vector3.new(0.15, 0.18, 108), Color=Color3.fromRGB(52, 54, 66)}, wearF)
		part({Name="Seam", Position=Vector3.new(0, y, -44.85), Size=Vector3.new(88, 0.18, 0.15), Color=Color3.fromRGB(52, 54, 66)}, wearF)
	end
	local function vent(cf)
		local m = Instance.new("Model"); m.Name = "Vent"; m.Parent = wearF
		local box = part({Name="VentBox", Size=Vector3.new(2.4, 1.5, 0.25), Color=Color3.fromRGB(30, 30, 38)}, m)
		box.CFrame = cf
		for i = 0, 2 do
			local slat = part({Name="Slat", Size=Vector3.new(2.1, 0.18, 0.12), Color=Color3.fromRGB(70, 72, 84)}, m)
			slat.CFrame = cf * CFrame.new(0, 0.42 - i * 0.42, -0.1) * CFrame.Angles(math.rad(25), 0, 0)
		end
	end
	vent(CFrame.new(-44.6, 4.2, -6) * CFrame.Angles(0, math.rad(-90), 0))
	vent(CFrame.new(-44.6, 4.2, 26) * CFrame.Angles(0, math.rad(-90), 0))
	vent(CFrame.new(44.6, 4.2, -6) * CFrame.Angles(0, math.rad(90), 0))
	vent(CFrame.new(44.6, 4.2, 26) * CFrame.Angles(0, math.rad(90), 0))
	local POSTERS = {
		{ pos = CFrame.new(-44.6, 8.5, -32) * CFrame.Angles(0, math.rad(-90), 0), bg = Color3.fromRGB(46, 34, 78), accent = Color3.fromRGB(120, 220, 255) },
		{ pos = CFrame.new(-44.6, 8.5, 54) * CFrame.Angles(0, math.rad(-90), 0), bg = Color3.fromRGB(78, 30, 54), accent = Color3.fromRGB(255, 170, 80) },
		{ pos = CFrame.new(44.6, 8.5, -32) * CFrame.Angles(0, math.rad(90), 0), bg = Color3.fromRGB(30, 60, 66), accent = Color3.fromRGB(120, 255, 170) },
		{ pos = CFrame.new(44.6, 8.5, 54) * CFrame.Angles(0, math.rad(90), 0), bg = Color3.fromRGB(70, 52, 26), accent = Color3.fromRGB(255, 130, 220) },
	}
	for _, info in ipairs(POSTERS) do
		local m = Instance.new("Model"); m.Name = "Poster"; m.Parent = wearF
		local bg = part({Name="PosterBg", Size=Vector3.new(2.6, 3.6, 0.12), Color=info.bg, Material=Enum.Material.SmoothPlastic}, m)
		bg.CFrame = info.pos * CFrame.Angles(0, 0, math.rad(wrng:NextNumber(-3, 3)))
		local planet = part({Name="PosterPlanet", Shape=Enum.PartType.Ball, Size=Vector3.new(1.2, 1.2, 1.2), Color=info.accent, Material=Enum.Material.Neon}, m)
		planet.CFrame = bg.CFrame * CFrame.new(0, 0.7, -0.12)
		for line = 0, 1 do
			part({Name="PosterLine", Size=Vector3.new(1.8 - line * 0.5, 0.16, 0.05), Color=Color3.fromRGB(225, 222, 214), Material=Enum.Material.SmoothPlastic}, m).CFrame =
				bg.CFrame * CFrame.new(0, -0.7 - line * 0.4, -0.1)
		end
	end
	for i = 1, 12 do
		local w = wrng:NextNumber(2.5, 6.5)
		local patch = part({Name="FloorPatch", Size=Vector3.new(w, 0.025, w * wrng:NextNumber(0.6, 1.3)),
			Color=Color3.fromRGB(34, 36, 46), Material=Enum.Material.Slate}, wearF)
		patch.CFrame = CFrame.new(wrng:NextNumber(-38, 38), 1.045, wrng:NextNumber(-38, 58)) * CFrame.Angles(0, math.rad(wrng:NextNumber(0, 180)), 0)
	end
	for i = 1, 5 do
		local crack = part({Name="Crack", Size=Vector3.new(0.12, 0.02, wrng:NextNumber(3, 7)), Color=Color3.fromRGB(22, 24, 32), Material=Enum.Material.SmoothPlastic}, wearF)
		crack.CFrame = CFrame.new(wrng:NextNumber(-36, 36), 1.055, wrng:NextNumber(-36, 56)) * CFrame.Angles(0, math.rad(wrng:NextNumber(0, 180)), 0)
	end
	local can = part({Name="TippedCan", Shape=Enum.PartType.Cylinder, Size=Vector3.new(2.6, 1.6, 1.6), Color=Color3.fromRGB(190, 190, 196), CanCollide=true}, wearF)
	can.CFrame = CFrame.new(-19, 1.85, 6) * CFrame.Angles(0, math.rad(35), 0)
	for i = 1, 3 do
		local cup = part({Name="SpilledCup", Shape=Enum.PartType.Cylinder, Size=Vector3.new(0.8, 0.55, 0.55), Color=Color3.fromRGB(230, 228, 220), Material=Enum.Material.SmoothPlastic}, wearF)
		cup.CFrame = CFrame.new(-19 + wrng:NextNumber(-2.5, 2.5), 1.35, 7.5 + wrng:NextNumber(-1.5, 1.5)) * CFrame.Angles(math.rad(wrng:NextNumber(0, 180)), math.rad(wrng:NextNumber(0, 180)), 0)
	end
	for i = 1, 9 do
		local paper = part({Name="Paper", Size=Vector3.new(0.9, 0.02, 1.2), Color=Color3.fromRGB(wrng:NextInteger(200, 235), wrng:NextInteger(198, 230), wrng:NextInteger(190, 220)), Material=Enum.Material.SmoothPlastic}, wearF)
		paper.CFrame = CFrame.new(wrng:NextNumber(-40, 40), 1.07, wrng:NextNumber(-40, 60)) * CFrame.Angles(0, math.rad(wrng:NextNumber(0, 360)), 0)
	end
	local crate1 = part({Name="Crate", Size=Vector3.new(2.4, 2.4, 2.4), Color=Color3.fromRGB(104, 74, 48), Material=Enum.Material.WoodPlanks, CanCollide=true}, wearF)
	crate1.CFrame = CFrame.new(-16, 2.25, 60) * CFrame.Angles(0, math.rad(12), 0)
	local crate2 = part({Name="Crate", Size=Vector3.new(1.9, 1.9, 1.9), Color=Color3.fromRGB(96, 66, 44), Material=Enum.Material.WoodPlanks, CanCollide=true}, wearF)
	crate2.CFrame = CFrame.new(-15.6, 4.4, 60.3) * CFrame.Angles(0, math.rad(-14), 0)

	-- ===== slijtage v2: plassen, druipsporen, poster-flapjes, pylonen, WET FLOOR, popcorn, blikjes, confetti =====
	local w2rng = Random.new(9001)
	local PUDDLES = { {-12, -18, 4.2}, {18, 30, 5.5}, {-30, 44, 3.4}, {8, -40, 3.0} }
	for _, q in ipairs(PUDDLES) do
		local puddle = part({Name="Puddle", Size=Vector3.new(q[3], 0.02, q[3] * w2rng:NextNumber(0.7, 1.1)),
			Color=Color3.fromRGB(28, 32, 44), Reflectance=0.28, Material=Enum.Material.Glass}, wearF)
		puddle.CFrame = CFrame.new(q[1], 1.06, q[2]) * CFrame.Angles(0, math.rad(w2rng:NextNumber(0, 180)), 0)
	end
	for _, v in ipairs(wearF:GetChildren()) do
		if v.Name == "Vent" then
			local box = v:FindFirstChild("VentBox")
			if box then
				for d = 0, 2 do
					local streak = part({Name="DripStain", Size=Vector3.new(0.18, w2rng:NextNumber(1.2, 2.2), 0.04),
						Color=Color3.fromRGB(40, 42, 50), Material=Enum.Material.SmoothPlastic}, v)
					streak.CFrame = box.CFrame * CFrame.new(-0.7 + d * 0.7, -(0.75 + streak.Size.Y / 2), -0.14)
				end
			end
		elseif v.Name == "Poster" then
			local bg = v:FindFirstChild("PosterBg")
			if bg then
				local peel = part({Name="PosterPeel", Size=Vector3.new(0.55, 0.55, 0.06), Color=bg.Color, Material=Enum.Material.SmoothPlastic}, v)
				peel.CFrame = bg.CFrame * CFrame.new(bg.Size.X/2 - 0.25, -bg.Size.Y/2 + 0.25, -0.08)
					* CFrame.Angles(math.rad(-16), math.rad(18), math.rad(8))
			end
		end
	end
	local function cone(x, z, tipped)
		local m = Instance.new("Model"); m.Name = "Cone"; m.Parent = wearF
		local base = CFrame.new(x, 1, z) * CFrame.Angles(0, math.rad(w2rng:NextNumber(0, 360)), 0)
		if tipped then base = base * CFrame.new(0, 0.5, 0) * CFrame.Angles(math.rad(90), 0, 0) end
		local foot = part({Name="ConeFoot", Size=Vector3.new(1.1, 0.14, 1.1), Color=Color3.fromRGB(230, 110, 40), Material=Enum.Material.SmoothPlastic, CanCollide=not tipped}, m)
		foot.CFrame = base * CFrame.new(0, 0.07, 0)
		for s = 0, 2 do
			local seg = part({Name="ConeSeg", Size=Vector3.new(0.72 - s * 0.2, 0.42, 0.72 - s * 0.2),
				Color=(s == 1) and Color3.fromRGB(235, 232, 225) or Color3.fromRGB(230, 110, 40), Material=Enum.Material.SmoothPlastic}, m)
			seg.CFrame = base * CFrame.new(0, 0.35 + s * 0.42, 0)
		end
	end
	cone(-8, 30, false); cone(-6.5, 32, true); cone(24, -14, true)
	local wfm = Instance.new("Model"); wfm.Name = "WetFloorSign"; wfm.Parent = wearF
	local wfCf = CFrame.new(-16.5, 1, 3.5) * CFrame.Angles(0, math.rad(40), 0)
	for _, s in ipairs({ -1, 1 }) do
		local plate = part({Name="SignPlate", Size=Vector3.new(1.5, 2.2, 0.08), Color=Color3.fromRGB(235, 205, 60), Material=Enum.Material.SmoothPlastic, CanCollide=true}, wfm)
		plate.CFrame = wfCf * CFrame.new(0, 1.05, s * 0.42) * CFrame.Angles(math.rad(s * -18), 0, 0)
		if s == -1 then
			local sg = Instance.new("SurfaceGui"); sg.Face = Enum.NormalId.Front; sg.Parent = plate
			local tl = Instance.new("TextLabel"); tl.Size = UDim2.new(1, 0, 0.5, 0); tl.Position = UDim2.new(0, 0, 0.25, 0)
			tl.BackgroundTransparency = 1; tl.Text = "WET FLOOR"; tl.TextScaled = true
			tl.TextColor3 = Color3.fromRGB(30, 30, 34); tl.Font = Enum.Font.Oswald; tl.Parent = sg
		end
	end
	for i = 1, 14 do
		local pop = part({Name="Popcorn", Size=Vector3.new(0.22, 0.18, 0.2),
			Color=Color3.fromRGB(w2rng:NextInteger(225, 245), w2rng:NextInteger(210, 235), w2rng:NextInteger(160, 200)),
			Material=Enum.Material.SmoothPlastic}, wearF)
		pop.CFrame = CFrame.new(-19 + w2rng:NextNumber(-3.5, 3.5), 1.12, 7 + w2rng:NextNumber(-3, 3))
			* CFrame.Angles(math.rad(w2rng:NextNumber(0, 360)), math.rad(w2rng:NextNumber(0, 360)), 0)
	end
	local CAN_COLORS = { Color3.fromRGB(190, 60, 60), Color3.fromRGB(70, 110, 190), Color3.fromRGB(110, 180, 90) }
	for i = 1, 5 do
		local can2 = part({Name="SodaCan", Shape=Enum.PartType.Cylinder, Size=Vector3.new(0.5, 0.34, 0.34),
			Color=CAN_COLORS[(i % #CAN_COLORS) + 1]}, wearF)
		can2.CFrame = CFrame.new(w2rng:NextNumber(-36, 36), 1.18, w2rng:NextNumber(-36, 56))
			* CFrame.Angles(math.rad(w2rng:NextNumber(0, 180)), math.rad(w2rng:NextNumber(0, 360)), 0)
	end
	local CONF_COLORS = { Color3.fromRGB(120, 220, 255), Color3.fromRGB(255, 170, 80), Color3.fromRGB(255, 130, 220), Color3.fromRGB(180, 120, 255) }
	for i = 1, 16 do
		local conf = part({Name="Confetti", Size=Vector3.new(0.28, 0.02, 0.28),
			Color=CONF_COLORS[(i % #CONF_COLORS) + 1], Material=Enum.Material.SmoothPlastic}, wearF)
		conf.CFrame = CFrame.new(w2rng:NextNumber(-10, 10), 1.075, 55 + w2rng:NextNumber(-6, 8))
			* CFrame.Angles(0, math.rad(w2rng:NextNumber(0, 360)), 0)
	end
	local balloon = part({Name="DeadBalloon", Size=Vector3.new(0.9, 0.12, 0.7), Color=Color3.fromRGB(200, 70, 70), Material=Enum.Material.SmoothPlastic}, wearF)
	balloon.CFrame = CFrame.new(-12.5, 1.1, 19.5) * CFrame.Angles(0, math.rad(30), 0)
	local bstring = part({Name="BalloonString", Size=Vector3.new(0.04, 0.02, 1.6), Color=Color3.fromRGB(230, 230, 235), Material=Enum.Material.SmoothPlastic}, wearF)
	bstring.CFrame = CFrame.new(-13.2, 1.06, 20.6) * CFrame.Angles(0, math.rad(-20), 0)
end

print("[Polish] Fase 11-decor herbouwd: nacht, licht, park, rad, raket — Spaceland leeft")
