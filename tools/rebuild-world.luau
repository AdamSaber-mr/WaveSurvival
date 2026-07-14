-- NOODHERSTEL-SCRIPT (verzekering): herbouwt alle wereld-objecten die niet via Script Sync lopen.
-- Dit bestand draait NIET mee in de game (de map "tools/" synct niet naar Studio).
-- Gebruik: plak dit script in de Studio command bar of laat Claude het via MCP uitvoeren.
-- Herbouwt: Workspace.Map (Spaceland spawn-plein v3), zombie-spawnmarkers, StarterGui.HUD, StarterPack.Pistol.

-- ===== DEEL 1: SPACELAND SPAWN-PLEIN =====
local ws = workspace
local old = ws:FindFirstChild("Map")
if old then old:Destroy() end

local map = Instance.new("Folder"); map.Name = "Map"; map.Parent = ws
local zonesF = Instance.new("Folder"); zonesF.Name = "Zones"; zonesF.Parent = map
local doorsF = Instance.new("Folder"); doorsF.Name = "Doors"; doorsF.Parent = map
local spawnsF = Instance.new("Folder"); spawnsF.Name = "ZombieSpawns"; spawnsF.Parent = map

local C = {
	floor   = Color3.fromRGB(48, 50, 62),
	wall    = Color3.fromRGB(78, 80, 92),
	shop    = Color3.fromRGB(62, 64, 78),
	roof    = Color3.fromRGB(40, 42, 54),
	counter = Color3.fromRGB(90, 92, 104),
	accent  = Color3.fromRGB(140, 110, 255),
	accent2 = Color3.fromRGB(90, 160, 255),
	barrier = Color3.fromRGB(110, 112, 120),
	planter = Color3.fromRGB(200, 200, 205),
	hedge   = Color3.fromRGB(34, 60, 38),
	screen  = Color3.fromRGB(18, 20, 32),
}

local function part(props, parent)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in pairs(props) do p[k] = v end
	p.Parent = parent
	return p
end

local function label(host, face, text, color, sizeY, posY)
	local sg = Instance.new("SurfaceGui"); sg.Face = face; sg.Parent = host
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.new(1, 0, sizeY or 0.5, 0)
	tl.Position = UDim2.new(0, 0, posY or 0.25, 0)
	tl.BackgroundTransparency = 1
	tl.Text = text
	tl.TextColor3 = color
	tl.TextScaled = true
	tl.Font = Enum.Font.Arcade
	tl.Parent = sg
end

-- plein: 90 breed (x -45..45), 110 diep (z -45..65)
local plaza = Instance.new("Model"); plaza.Name = "SpawnPlaza"; plaza:SetAttribute("ZoneId", "SpawnPlaza"); plaza.Parent = zonesF
part({Name="Floor", Position=Vector3.new(0, 0.5, 10), Size=Vector3.new(90, 1, 110), Color=C.floor, Material=Enum.Material.Slate}, plaza)
part({Name="Wall_West",  Position=Vector3.new(-46, 11, 10), Size=Vector3.new(2, 20, 114), Color=C.wall}, plaza)
part({Name="Wall_East",  Position=Vector3.new(46, 11, 10),  Size=Vector3.new(2, 20, 114), Color=C.wall}, plaza)
part({Name="Wall_North", Position=Vector3.new(0, 11, -46),  Size=Vector3.new(94, 20, 2), Color=C.wall}, plaza)

-- SPACELAND-poort (noord, boven de spawn)
part({Name="ArchPillar_L", Position=Vector3.new(-12, 9, -44), Size=Vector3.new(3, 16, 3), Color=C.wall, Material=Enum.Material.Concrete}, plaza)
part({Name="ArchPillar_R", Position=Vector3.new(12, 9, -44),  Size=Vector3.new(3, 16, 3), Color=C.wall, Material=Enum.Material.Concrete}, plaza)
local beam = part({Name="ArchBeam", Position=Vector3.new(0, 18.5, -44), Size=Vector3.new(27, 4, 3), Color=C.accent, Material=Enum.Material.Neon}, plaza)
label(beam, Enum.NormalId.Back, "★ SPACELAND ★", Color3.fromRGB(20, 20, 30), 0.8, 0.1)

-- winkels: 3 west + 3 oost
local shopNames = {
	west = {"ASTRO SNACKS", "MOON BURGER", "STAR SOUVENIRS"},
	east = {"COMET CANDY", "LASER LANES", "ORBIT OUTFITS"},
}
local function shop(side, index, centerZ, name)
	local m = Instance.new("Model"); m.Name = "Shop_" .. name:gsub(" ", ""); m.Parent = plaza
	local sgn = (side == "west") and 1 or -1
	local cx = (side == "west") and -40 or 40
	for _, dz in ipairs({-8, 8}) do
		part({Name="ShopSide", Position=Vector3.new(cx, 7, centerZ + dz), Size=Vector3.new(10, 12, 1), Color=C.shop}, m)
	end
	local roof = part({Name="ShopRoof", Position=Vector3.new(cx + sgn * 0.5, 13.5, centerZ), Size=Vector3.new(11, 1, 17), Color=C.roof}, m)
	local light = Instance.new("PointLight"); light.Color = Color3.fromRGB(255, 235, 200); light.Range = 14; light.Brightness = 0.8; light.Parent = roof
	part({Name="ShopCounter", Position=Vector3.new(cx + sgn * 3, 2.75, centerZ), Size=Vector3.new(3, 3.5, 12), Color=C.counter, Material=Enum.Material.Metal}, m)
	local board = part({Name="ShopSign", Position=Vector3.new(cx + sgn * 5, 15.5, centerZ), Size=Vector3.new(0.8, 3, 14), Color=C.roof}, m)
	local face = (side == "west") and Enum.NormalId.Right or Enum.NormalId.Left
	label(board, face, name, index % 2 == 0 and C.accent2 or C.accent, 1, 0)
end
for i, z in ipairs({-20, 10, 40}) do shop("west", i, z, shopNames.west[i]) end
for i, z in ipairs({-20, 10, 40}) do shop("east", i, z, shopNames.east[i]) end

-- plantenbak-hulpje
local function hedgePlanter(name, pos, parent)
	local m = Instance.new("Model"); m.Name = name; m.Parent = parent
	part({Name="PlanterBase", Position=pos, Size=Vector3.new(16, 3, 5), Color=C.planter, Material=Enum.Material.Concrete}, m)
	part({Name="Hedge", Position=pos + Vector3.new(0, 3.5, 0), Size=Vector3.new(15, 4, 4), Color=C.hedge, Material=Enum.Material.Grass}, m)
	return m
end

-- middenlijn: struik (z=5) → park-map (z=32) → poort-struik (z=65)
hedgePlanter("Planter_Hedge_Mid", Vector3.new(0, 2.5, 5), plaza)
local mapM = Instance.new("Model"); mapM.Name = "ParkMapDisplay"; mapM.Parent = plaza
part({Name="MapBase", Position=Vector3.new(0, 2.25, 32), Size=Vector3.new(14, 2.5, 5), Color=C.planter, Material=Enum.Material.Concrete}, mapM)
local screen = part({Name="MapScreen", Position=Vector3.new(0, 6.5, 32), Size=Vector3.new(11, 6, 0.8), Color=C.screen, Material=Enum.Material.Glass}, mapM)
label(screen, Enum.NormalId.Front, "SPACELAND\nPARK MAP", C.accent2, 0.7, 0.15)
label(screen, Enum.NormalId.Back,  "SPACELAND\nPARK MAP", C.accent2, 0.7, 0.15)
local glow = Instance.new("PointLight"); glow.Color = C.accent2; glow.Range = 10; glow.Brightness = 0.6; glow.Parent = screen

-- koopmuur: 2 delen + struik-bak in het midden
local doorModel = Instance.new("Model"); doorModel.Name = "Door_MainStreet"; doorModel.Parent = doorsF
doorModel:SetAttribute("Cost", 750)
doorModel:SetAttribute("TargetZone", "MainStreet")
local function barrierSegment(name, cx)
	local seg = part({Name=name, Position=Vector3.new(cx, 7, 65), Size=Vector3.new(36, 12, 2), Color=C.barrier, Material=Enum.Material.Concrete}, doorModel)
	part({Name=name.."_Trim", Position=Vector3.new(cx, 13.25, 65), Size=Vector3.new(36, 0.5, 2), Color=C.accent, Material=Enum.Material.Neon}, doorModel)
	label(seg, Enum.NormalId.Front, "THIS AREA IS TEMPORARILY CLOSED", Color3.fromRGB(190, 190, 200), 0.22, 0.1)
	label(seg, Enum.NormalId.Back,  "THIS AREA IS TEMPORARILY CLOSED", Color3.fromRGB(190, 190, 200), 0.22, 0.1)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ObjectText = "Main Street"
	prompt.ActionText = "Open Area  ($750)"
	prompt.HoldDuration = 0.6
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = seg
	return seg
end
barrierSegment("Barrier_Left", -27)
barrierSegment("Barrier_Right", 27)
hedgePlanter("Planter_Hedge_Gate", Vector3.new(0, 2.5, 65), doorModel)
part({Name="HedgeTop", Position=Vector3.new(0, 7.5, 65), Size=Vector3.new(15, 4, 4), Color=C.hedge, Material=Enum.Material.Grass}, doorModel)
-- anti-klim-strook: onzichtbaar, dekt ook de kiertjes naast de bak; zakt mee weg bij aankoop
part({Name="Barrier_Topper", Position=Vector3.new(0, 11.5, 65), Size=Vector3.new(18, 5, 2.5), Transparency=1, CanCollide=true}, doorModel)

-- Main Street teaser
part({Name="MainStreetStub", Position=Vector3.new(0, 0.5, 80), Size=Vector3.new(44, 1, 28), Color=Color3.fromRGB(38, 40, 50), Material=Enum.Material.Slate}, plaza)

-- zombie-spawnmarkers (Adams 4 cirkel-plekken: 2 achterhoeken + in 2 winkels)
local f = Instance.new("Folder"); f.Name = "SpawnPlaza"; f.Parent = spawnsF
local points = {
	{name = "Spawn_HoekNW",       pos = Vector3.new(-40, 2, -38)},
	{name = "Spawn_HoekNE",       pos = Vector3.new(40, 2, -38)},
	{name = "Spawn_MoonBurger",   pos = Vector3.new(-41, 2, 10)},
	{name = "Spawn_OrbitOutfits", pos = Vector3.new(41, 2, 40)},
}
for _, pt in ipairs(points) do
	local p = part({Name=pt.name, Position=pt.pos, Size=Vector3.new(2, 2, 2), Transparency=1, CanCollide=false, CanQuery=false, CanTouch=false}, f)
	p:SetAttribute("Zone", "SpawnPlaza")
end

-- speler-spawn achteraan onder de poort, kijkend het park in
local sl = ws:FindFirstChild("SpawnLocation")
if sl then
	sl.CFrame = CFrame.new(0, 1 + sl.Size.Y/2, -38) * CFrame.Angles(0, math.rad(180), 0)
end

-- lighting
local L = game:GetService("Lighting")
L.ClockTime = 17.2
L.OutdoorAmbient = Color3.fromRGB(100, 100, 130)
L.Ambient = Color3.fromRGB(70, 70, 90)

-- ===== DEEL 2: HUD =====
-- De HUD wordt sinds de CoD-HUD-update volledig door StarterPlayerScripts/HUDClient
-- in code gebouwd (SpacelandHUD) — hier is dus niets meer te herbouwen.

-- ===== DEEL 3: WAPENS =====
-- Alle wapens (Pistol/SMG/Shotgun/RayGun) worden gebouwd door tools/build-weapons.luau
-- (draai dat script na dit script).

-- ===== DEEL 4: WALL-BUYS (fase 7) =====
-- (wapen-templates: zie tools/build-weapons.luau)

local oldWB = map:FindFirstChild("WallBuys")
if oldWB then oldWB:Destroy() end
local wallBuys = Instance.new("Folder"); wallBuys.Name = "WallBuys"; wallBuys.Parent = map

local function wallBuy(weaponName, price, wallX, z, accentColor)
	local sgn = wallX > 0 and -1 or 1
	local station = Instance.new("Model"); station.Name = "WallBuy_" .. weaponName; station.Parent = wallBuys
	station:SetAttribute("Weapon", weaponName)
	station:SetAttribute("Price", price)
	local board = Instance.new("Part")
	board.Name = "Board"
	board.Anchored = true; board.CanCollide = false
	board.Size = Vector3.new(0.4, 4, 8)
	board.Position = Vector3.new(wallX + sgn * 0.4, 8, z)
	board.Color = Color3.fromRGB(25, 25, 35)
	board.Material = Enum.Material.SmoothPlastic
	board.Parent = station
	local sgui = Instance.new("SurfaceGui")
	sgui.Face = (wallX > 0) and Enum.NormalId.Left or Enum.NormalId.Right
	sgui.Parent = board
	local tl = Instance.new("TextLabel")
	tl.Size = UDim2.new(1, 0, 1, 0)
	tl.BackgroundTransparency = 1
	tl.Text = weaponName .. "\n$" .. price
	tl.TextColor3 = accentColor
	tl.TextScaled = true
	tl.Font = Enum.Font.Arcade
	tl.Parent = sgui
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "BuyPrompt"
	prompt.ObjectText = weaponName
	prompt.ActionText = "Buy  ($" .. price .. ")"
	prompt.HoldDuration = 0.6
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt.Parent = board
end

wallBuy("SMG", 1000, 45, 25, Color3.fromRGB(90, 160, 255))
wallBuy("Shotgun", 1500, -45, 25, Color3.fromRGB(255, 150, 0))

-- ===== DEEL 5: MYSTERY BOX (fase 8) =====
-- (RayGun-template: zie tools/build-weapons.luau)

local mbox = Instance.new("Model"); mbox.Name = "MysteryBox"; mbox.Parent = map
local crate = Instance.new("Part")
crate.Name = "Crate"; crate.Anchored = true
crate.Size = Vector3.new(4.5, 2.5, 3); crate.Position = Vector3.new(0, 2.25, 80)
crate.Color = Color3.fromRGB(70, 50, 90); crate.Material = Enum.Material.WoodPlanks
crate.Parent = mbox
local lid = Instance.new("Part")
lid.Name = "Lid"; lid.Anchored = true
lid.Size = Vector3.new(4.7, 0.4, 3.2); lid.Position = Vector3.new(0, 3.7, 80)
lid.Color = Color3.fromRGB(50, 35, 65); lid.Material = Enum.Material.WoodPlanks
lid.Parent = mbox
for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
	local sg3 = Instance.new("SurfaceGui"); sg3.Face = face; sg3.Parent = crate
	local tl3 = Instance.new("TextLabel")
	tl3.Size = UDim2.new(1, 0, 1, 0); tl3.BackgroundTransparency = 1
	tl3.Text = "?"; tl3.TextColor3 = Color3.fromRGB(255, 220, 90); tl3.TextScaled = true; tl3.Font = Enum.Font.Arcade
	tl3.Parent = sg3
end
local mbGlow = Instance.new("PointLight"); mbGlow.Color = Color3.fromRGB(200, 160, 255); mbGlow.Range = 10; mbGlow.Brightness = 1; mbGlow.Parent = crate
local display = Instance.new("Part")
display.Name = "Display"; display.Anchored = true
display.Size = Vector3.new(1, 1, 1); display.Position = Vector3.new(0, 6.5, 80)
display.Transparency = 1; display.CanCollide = false
display.Parent = mbox
local mbb = Instance.new("BillboardGui"); mbb.Size = UDim2.new(0, 260, 0, 60); mbb.MaxDistance = 80; mbb.Parent = display
local mrl = Instance.new("TextLabel")
mrl.Name = "RollLabel"; mrl.Size = UDim2.new(1, 0, 1, 0); mrl.BackgroundTransparency = 1
mrl.Text = ""; mrl.TextColor3 = Color3.fromRGB(255, 220, 90); mrl.TextScaled = true; mrl.Font = Enum.Font.Arcade
mrl.TextStrokeColor3 = Color3.fromRGB(20, 20, 25); mrl.TextStrokeTransparency = 0.4
mrl.Parent = mbb
local mbPrompt = Instance.new("ProximityPrompt")
mbPrompt.Name = "BoxPrompt"; mbPrompt.ObjectText = "Mystery Box"; mbPrompt.ActionText = "Open  ($950)"
mbPrompt.HoldDuration = 0.6; mbPrompt.MaxActivationDistance = 10; mbPrompt.RequiresLineOfSight = false
mbPrompt.Parent = crate

-- ===== DEEL 6: PERK-AUTOMATEN (fase 9) =====
local perkF = Instance.new("Folder"); perkF.Name = "PerkMachines"; perkF.Parent = map
local function perkMachine(perkName, displayName, price, pos, rotY, color)
	local m = Instance.new("Model"); m.Name = "Perk_" .. perkName; m.Parent = perkF
	m:SetAttribute("Perk", perkName)
	m:SetAttribute("Price", price)
	local body = Instance.new("Part")
	body.Name = "Body"; body.Anchored = true
	body.Size = Vector3.new(3, 7, 2)
	body.CFrame = CFrame.new(pos) * CFrame.Angles(0, math.rad(rotY), 0)
	body.Color = color; body.Material = Enum.Material.SmoothPlastic
	body.Parent = m
	local top = Instance.new("Part")
	top.Name = "TopGlow"; top.Anchored = true
	top.Size = Vector3.new(3, 0.6, 2)
	top.CFrame = body.CFrame * CFrame.new(0, 3.8, 0)
	top.Color = color; top.Material = Enum.Material.Neon
	top.Parent = m
	local psg = Instance.new("SurfaceGui"); psg.Face = Enum.NormalId.Front; psg.Parent = body
	local ptl = Instance.new("TextLabel")
	ptl.Size = UDim2.new(1, 0, 0.35, 0); ptl.Position = UDim2.new(0, 0, 0.08, 0)
	ptl.BackgroundTransparency = 1
	ptl.Text = displayName; ptl.TextColor3 = Color3.fromRGB(245, 245, 250); ptl.TextScaled = true; ptl.Font = Enum.Font.Arcade
	ptl.TextStrokeColor3 = Color3.fromRGB(20, 20, 25); ptl.TextStrokeTransparency = 0.3
	ptl.Parent = psg
	local plight = Instance.new("PointLight"); plight.Color = color; plight.Range = 8; plight.Brightness = 1; plight.Parent = top
	local pprompt = Instance.new("ProximityPrompt")
	pprompt.Name = "PerkPrompt"; pprompt.ObjectText = displayName; pprompt.ActionText = "Drink  ($" .. price .. ")"
	pprompt.HoldDuration = 0.6; pprompt.MaxActivationDistance = 10; pprompt.RequiresLineOfSight = false
	pprompt.Parent = body
end
perkMachine("Juggernog", "JUGGERNOG", 2500, Vector3.new(-14, 4.5, 80), 90, Color3.fromRGB(220, 60, 60))
perkMachine("SpeedCola", "SPEED COLA", 2000, Vector3.new(-43, 4.5, -32), 90, Color3.fromRGB(80, 220, 100))
perkMachine("StaminUp", "STAMIN-UP", 1500, Vector3.new(43, 4.5, -32), -90, Color3.fromRGB(240, 210, 80))

print("[Rebuild] Wereld herbouwd: Map, spawn-markers, HUD, Pistol, Weapons, WallBuys, MysteryBox, PerkMachines")
