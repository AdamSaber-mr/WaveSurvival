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
	local p = part({Name=pt.name, Position=pt.pos, Size=Vector3.new(2, 2, 2), Transparency=1, CanCollide=false}, f)
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
local sg2 = game:GetService("StarterGui")
local oldHud = sg2:FindFirstChild("HUD")
if oldHud then oldHud:Destroy() end
local hud = Instance.new("ScreenGui"); hud.Name = "HUD"; hud.ResetOnSpawn = false

local money = Instance.new("TextLabel")
money.Name = "MoneyLabel"
money.AnchorPoint = Vector2.new(1, 1); money.Position = UDim2.new(1, -24, 1, -24); money.Size = UDim2.new(0, 220, 0, 42)
money.BackgroundTransparency = 1; money.Font = Enum.Font.Arcade; money.TextScaled = true
money.TextXAlignment = Enum.TextXAlignment.Right
money.TextColor3 = Color3.fromRGB(245, 205, 80); money.TextStrokeColor3 = Color3.fromRGB(20, 20, 25); money.TextStrokeTransparency = 0.4
money.Text = "$500"; money.Parent = hud

local roundLabel = Instance.new("TextLabel")
roundLabel.Name = "RoundLabel"
roundLabel.AnchorPoint = Vector2.new(0, 1); roundLabel.Position = UDim2.new(0, 24, 1, -24); roundLabel.Size = UDim2.new(0, 180, 0, 42)
roundLabel.BackgroundTransparency = 1; roundLabel.Font = Enum.Font.Arcade; roundLabel.TextScaled = true
roundLabel.TextXAlignment = Enum.TextXAlignment.Left
roundLabel.TextColor3 = Color3.fromRGB(225, 85, 85); roundLabel.TextStrokeColor3 = Color3.fromRGB(20, 20, 25); roundLabel.TextStrokeTransparency = 0.4
roundLabel.Text = "WAVE -"; roundLabel.Parent = hud

local announce = Instance.new("TextLabel")
announce.Name = "RoundAnnounce"
announce.AnchorPoint = Vector2.new(0.5, 0.5); announce.Position = UDim2.new(0.5, 0, 0.3, 0); announce.Size = UDim2.new(0, 500, 0, 80)
announce.BackgroundTransparency = 1; announce.Font = Enum.Font.Arcade; announce.TextScaled = true
announce.TextColor3 = Color3.fromRGB(225, 85, 85); announce.TextStrokeColor3 = Color3.fromRGB(20, 20, 25)
announce.TextTransparency = 1; announce.TextStrokeTransparency = 1; announce.Text = ""
announce.Parent = hud
hud.Parent = sg2

-- ===== DEEL 3: PISTOL IN STARTERPACK =====
local sp = game:GetService("StarterPack")
local oldPistol = sp:FindFirstChild("Pistol")
if oldPistol then oldPistol:Destroy() end
local tool = Instance.new("Tool")
tool.Name = "Pistol"; tool.ToolTip = "Pistol — click to shoot"; tool.CanBeDropped = false
local handle = part({Name="Handle", Size=Vector3.new(0.45, 1.1, 0.5), Color=Color3.fromRGB(45, 45, 55), Material=Enum.Material.Metal, CanCollide=false, Anchored=false}, tool)
local body = part({Name="Body", Size=Vector3.new(0.4, 0.4, 1.7), Color=Color3.fromRGB(70, 70, 85), Material=Enum.Material.Metal, CanCollide=false, Anchored=false}, tool)
body.CFrame = handle.CFrame * CFrame.new(0, 0.65, -0.45)
local glow2 = part({Name="Glow", Size=Vector3.new(0.42, 0.12, 0.5), Color=Color3.fromRGB(90, 160, 255), Material=Enum.Material.Neon, CanCollide=false, Anchored=false}, tool)
glow2.CFrame = body.CFrame * CFrame.new(0, -0.2, 0.2)
local w1 = Instance.new("WeldConstraint"); w1.Part0 = handle; w1.Part1 = body; w1.Parent = handle
local w2 = Instance.new("WeldConstraint"); w2.Part0 = handle; w2.Part1 = glow2; w2.Parent = handle
tool.GripPos = Vector3.new(0, -0.25, 0.1)
tool.Parent = sp

print("[Rebuild] Wereld herbouwd: Map, spawn-markers, HUD, Pistol")
