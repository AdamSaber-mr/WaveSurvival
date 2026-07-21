-- NOODHERSTEL-SCRIPT deel 3: herbouwt alle wapen-Tools (v3.1, marketplace-modellen).
-- Draai na tools/rebuild-world.luau, in de Studio-COMMANDOBALK (Edit-mode).
-- (InsertService werkt niet vanuit de MCP-plugin-context; commandobalk wel.)
-- Bouwt: StarterPack.Pistol en ServerStorage.Weapons.SMG/Shotgun/RayGun.
--
-- v3: de wapens zijn geen zelfgebouwde blokjes meer maar gratis modellen van
-- de Creator Store (gekozen op 2026-07-16 met Adams akkoord):
--   · 5722821580  "QUARANTINE-Z GUN WEAPON AMMO PACK LOW POLY"
--        → M1911_1 (Pistol), UMP45 (SMG), Shotgun (pump-shotgun met hout)
--   · 434887296   "Ray Gun" (klassieke CoD Ray Gun-replica, brick-built)
-- Elk wapen krijgt: een onzichtbare Handle ín de greep, een onzichtbare
-- "Muzzle"-marker op de loopmond, en WeldConstraints aan de Handle.
--
-- GELEERDE LESSEN (v3.1, na Adams playtest):
--  · De QZ-wapens liggen PLAT op een displaybord; hun Model-pivot is wél
--    canoniek (rechtop, loop +X). Dus: clone als Model laten en met PivotTo
--    rechtzetten — NOOIT parts los verplaatsen vóór het draaien.
--  · Shotgun-roll: X→+Y (X→-Y zette hem ondersteboven).
--  · Ray Gun: canonieke pose heeft de loop al op -Z → rot = identiteit
--    (een extra 180° zette hem achterstevoren). Groene meter = achterkant!
--  · De modellen bevatten rig-hulpblokjes (Main/CAMERA/AimPart en een eigen
--    'Handle'-blokje!) — verbergen en hernoemen, anders pakt Roblox de
--    verkeerde Handle en "zweeft" het wapen naast je hand.
--  · Ray Gun-PointLight stond op brightness 100.000.000 (grap) → 0.5/range 3.
--
-- GELEERDE LESSEN (v3.2, na Adams tweede playtest):
--  · De SMG was "kapot": bij de UMP45 heet de ECHTE romp óók 'Main' en de
--    ECHTE greep óók 'Handle'. Die werden dus samen met de hulpblokjes
--    onzichtbaar gemaakt → alleen loop, bout, magazijn en kolf bleven los
--    zweven. Nieuwe regel: alleen kale Parts (de hulpblokjes zijn altijd
--    simpele blokjes) mogen verborgen worden; MeshParts en Unions zijn echte
--    geometrie en blijven ALTIJD zichtbaar. Hernoemen doen we wel altijd,
--    anders pakt Roblox de verkeerde Handle.
--  · De shotgun was een "stokje": de oude verdikking rekte alleen de BREEDTE
--    (wereld-X) op, nooit de HOOGTE. Gemeten: 4.03 lang × 0.65 hoog × 0.29
--    breed, terwijl de veel kortere SMG al 1.13 hoog is. Nu 'girth' = twee
--    factoren (breedte én hoogte) die vóór het plaatsen van de Handle op het
--    hele model worden losgelaten, zodat greep en loopmond meeschalen.
--
-- GELEERDE LESSEN (v3.3, gemeten in Studio i.p.v. gegokt):
--  · BRONCACHE — BELANGRIJK: InsertService:LoadAsset geeft sinds 2026-07-21
--    OVERAL "User is not authorized to access Asset" (ook in de commandobalk):
--    de twee gratis modellen zijn van de Creator Store verdwenen. De enige
--    kopie die er nog is, staat in ServerStorage.SourceAssets — VERWIJDER DIE
--    MAP NOOIT, anders zijn de wapens definitief weg. Dit script pakt die
--    cache; LoadAsset is alleen nog een noodgreep. Zie ook
--    tools/cache-weapon-assets.luau.
--    Bijvangst: omdat de cache in de place staat, kan het bouwen nu ook via de
--    MCP-plugin draaien — dus mét screenshots en metingen ter controle, in
--    plaats van blind gokken en Adam laten playtesten.
--  · DUBBELE VERDIKKING: bij een BlockMesh/CylinderMesh is de getoonde maat
--    Part.Size × Mesh.Scale. De oude code rekte ALLEBEI op → die delen werden
--    girth² keer dikker (2.0 werd 4.0) terwijl de Unions ernaast maar 2.0 keer
--    dikker werden: uit verhouding. Nu: een FileMesh (echt 3D-model) schaalt
--    via Mesh.Scale, al het andere via Part.Size — nooit allebei.
--  · GEMETEN shotgun: loop-Unions waren 0.11–0.12 dik bij lengte 4.3 (1:35 =
--    een stokje). Nu korter (3.8) en fors dikker (×2.6 breed, ×2.4 hoog).

local InsertService = game:GetService("InsertService")
local sp = game:GetService("StarterPack")
local ss = game:GetService("ServerStorage")

local weaponsF = ss:FindFirstChild("Weapons")
if not weaponsF then
	weaponsF = Instance.new("Folder"); weaponsF.Name = "Weapons"; weaponsF.Parent = ss
end

-- rommel uit gratis modellen slopen (scripts! geluiden, waardes, oude lasjes)
local function stripJunk(inst)
	for _, d in ipairs(inst:GetDescendants()) do
		if d:IsA("LuaSourceContainer") or d:IsA("Sound") or d:IsA("Camera") or d:IsA("ValueBase")
			or d.ClassName == "TouchTransmitter" or d:IsA("JointInstance") or d:IsA("Attachment") then
			d:Destroy()
		end
	end
end

-- wereld-AABB over alle parts (met hoekpunten, dus gedraaide delen kloppen ook)
local function worldAABB(container)
	local minV = Vector3.new(math.huge, math.huge, math.huge)
	local maxV = Vector3.new(-math.huge, -math.huge, -math.huge)
	for _, p in ipairs(container:GetDescendants()) do
		if p:IsA("BasePart") then
			local cf, half = p.CFrame, p.Size / 2
			for dx = -1, 1, 2 do
				for dy = -1, 1, 2 do
					for dz = -1, 1, 2 do
						local corner = cf:PointToWorldSpace(Vector3.new(half.X * dx, half.Y * dy, half.Z * dz))
						minV = Vector3.new(math.min(minV.X, corner.X), math.min(minV.Y, corner.Y), math.min(minV.Z, corner.Z))
						maxV = Vector3.new(math.max(maxV.X, corner.X), math.max(maxV.Y, corner.Y), math.max(maxV.Z, corner.Z))
					end
				end
			end
		end
	end
	return (minV + maxV) / 2, maxV - minV
end

-- assets laden en meteen verankeren (anders valt het pack kapot op de baseplate).
-- Eerst kijken in ServerStorage.SourceAssets (gevuld door cache-weapon-assets.luau):
-- dan werkt dit script óók vanuit de MCP-plugin, die geen InsertService mag.
local function loadAsset(assetId)
	local container
	local cache = ss:FindFirstChild("SourceAssets")
	local cached = cache and cache:FindFirstChild("Asset_" .. assetId)
	if cached then
		container = cached:Clone()
	else
		container = InsertService:LoadAsset(assetId)
	end
	for _, d in ipairs(container:GetDescendants()) do
		if d:IsA("BasePart") then d.Anchored = true end
	end
	return container
end
local qzContainer = loadAsset(5722821580)
local qzPack = qzContainer:FindFirstChildOfClass("Model")
local rayContainer = loadAsset(434887296)
local raySource = rayContainer:FindFirstChild("RAY GUN", true)

-- girth = verdikking loodrecht op de loop: {breedte (wereld-X), hoogte (wereld-Y)}.
-- De lengte (wereld-Z) blijft altijd targetLength — een wapen wordt dus dikker
-- en steviger, nooit langer. (Adams feedback: QZ-wapens zijn van zichzelf erg
-- dun; shotgun en raygun moeten dik/stoer ogen.)
local CONFIG = {
	{ toolName = "Pistol", src = qzPack:FindFirstChild("M1911_1"),
	  rot = CFrame.Angles(0, math.rad(90), 0), targetLength = 1.9, girthX = 1, girthY = 1,
	  gripY = -0.18, gripZ = 0.30, muzzleY = 0.34, tip = "Pistol", dest = sp },
	{ toolName = "SMG", src = qzPack:FindFirstChild("UMP45"),
	  rot = CFrame.Angles(0, math.rad(90), 0), targetLength = 2.9, girthX = 1.35, girthY = 1,
	  gripY = -0.24, gripZ = 0.26, muzzleY = 0.15, tip = "SMG — hold to fire", dest = weaponsF },
	-- shotgun: het BRONmodel is van zichzelf slank — 4.13 lang bij 0.70 hoog
	-- (1:6), terwijl de UMP45 4.30 bij 1.94 is (1:2). Hij werd óók nog langer
	-- gemaakt dan de SMG; vandaar het "stokje". Nu korter (3.8) én fors
	-- bonkiger: zichtbaar resultaat is 0.39 breed × 1.38 hoog × 3.57 lang.
	{ toolName = "Shotgun", src = qzPack:FindFirstChild("Shotgun"),
	  rot = CFrame.fromMatrix(Vector3.zero, Vector3.new(0, 1, 0), Vector3.new(0, 0, -1), Vector3.new(-1, 0, 0)),
	  targetLength = 3.8, girthX = 2.6, girthY = 2.4,
	  gripY = -0.08, gripZ = 0.30, muzzleY = 0.30, tip = "Shotgun — devastating up close", dest = weaponsF },
	{ toolName = "RayGun", src = raySource,
	  rot = CFrame.new(), targetLength = 3.6, girthX = 1.5, girthY = 1,
	  gripY = -0.22, gripZ = 0.30, muzzleY = 0.08, tip = "Ray Gun — the jackpot", dest = weaponsF,
	  renameHandle = true, anchorToOriginalHandle = true },
}

-- welke LOKALE as van dit deel wijst het meest langs een wereld-richting?
-- (nodig omdat losse onderdelen gedraaid in het model zitten: "de breedte"
--  is voor het ene deel zijn X-maat en voor het andere zijn Z-maat)
local function dominantAxis(v, exclude)
	local a = { math.abs(v.X), math.abs(v.Y), math.abs(v.Z) }
	local best, bestValue = 1, -1
	for i = 1, 3 do
		if i ~= exclude and a[i] > bestValue then
			best, bestValue = i, a[i]
		end
	end
	return best
end

-- Het hele wapen dikker maken: breedte × girthX, hoogte × girthY, lengte gelijk.
-- Zowel de MATEN als de POSITIES schalen mee (rond het pivot), zodat het één
-- net uitgerekt wapen blijft en er geen gaten tussen de onderdelen vallen.
local function applyGirth(container, girthX, girthY, pivot)
	if girthX == 1 and girthY == 1 then return end
	for _, p in ipairs(container:GetDescendants()) do
		if p:IsA("BasePart") then
			local ix = dominantAxis(p.CFrame:VectorToObjectSpace(Vector3.new(1, 0, 0)))
			local iy = dominantAxis(p.CFrame:VectorToObjectSpace(Vector3.new(0, 1, 0)), ix)
			local f = { 1, 1, 1 }
			f[ix], f[iy] = girthX, girthY
			local factor = Vector3.new(f[1], f[2], f[3])
			-- ÉÉN van de twee, nooit allebei (anders girth²):
			--  · FileMesh (ingeladen 3D-model): getoonde maat = Mesh.Scale, Part.Size
			--    doet niets voor het beeld → alleen de Scale oprekken.
			--  · BlockMesh/CylinderMesh/geen mesh (Part, MeshPart, Union): getoonde
			--    maat volgt Part.Size → alleen de Size oprekken.
			local fileMesh
			for _, child in ipairs(p:GetChildren()) do
				if child:IsA("SpecialMesh") and child.MeshType == Enum.MeshType.FileMesh then
					fileMesh = child
				end
			end
			if fileMesh then
				fileMesh.Scale = fileMesh.Scale * factor
			else
				p.Size = p.Size * factor
			end
			local pos = p.Position
			p.CFrame = (p.CFrame - pos) + Vector3.new(
				pivot.X + (pos.X - pivot.X) * girthX,
				pivot.Y + (pos.Y - pivot.Y) * girthY,
				pos.Z)
		end
	end
end

for _, cfg in ipairs(CONFIG) do
	assert(cfg.src, "bronmodel ontbreekt voor " .. cfg.toolName)
	local clone = cfg.src:Clone()
	stripJunk(clone)
	if cfg.renameHandle then
		-- de Ray Gun-Tool heeft al een 'Handle' als zichtbaar greep-deel
		local oldHandle = clone:FindFirstChild("Handle")
		if oldHandle then oldHandle.Name = "GripBody" end
	end
	for _, d in ipairs(clone:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanQuery = false
			d.CanTouch = false
			d.Massless = true
		end
	end
	clone.Parent = workspace
	local anchor = CFrame.new(0, 100, 0)
	if cfg.anchorToOriginalHandle then
		-- Ray Gun-methode: her-poseer het wapen rond de ORIGINELE greep van de
		-- maker (GripBody). Dan weten we ZEKER hoe hij bedoeld is om vast te
		-- houden: greep op de oorsprong, loop naar -Z. Geen giswerk.
		local gripBody = clone:FindFirstChild("GripBody", true)
		assert(gripBody, "GripBody (originele Handle) ontbreekt voor " .. cfg.toolName)
		local T = gripBody.CFrame
		for _, d in ipairs(clone:GetDescendants()) do
			if d:IsA("BasePart") then
				d.CFrame = anchor * T:ToObjectSpace(d.CFrame)
			end
		end
	else
		-- QZ-methode: PivotTo op het MODEL zet het wapen in zijn canonieke
		-- houding (weg van de platte display-pose) en draait naar loop = -Z
		if clone:IsA("Model") then
			clone:PivotTo(anchor * cfg.rot)
		end
	end

	local _, size1 = worldAABB(clone)
	if clone:IsA("Model") then
		if cfg.anchorToOriginalHandle then
			clone.WorldPivot = anchor -- schalen om de greep: die blijft op zijn plek
		end
		clone:ScaleTo(cfg.targetLength / size1.Z)
	end

	-- verdikken gebeurt NU, vóór de Handle en de Muzzle worden gemaakt: die
	-- worden hieronder uit de definitieve afmetingen berekend en zitten dus
	-- vanzelf goed (greep in de greep, loopmond op de loop)
	local girthPivot = cfg.anchorToOriginalHandle and anchor.Position or select(1, worldAABB(clone))
	applyGirth(clone, cfg.girthX or 1, cfg.girthY or 1, girthPivot)

	local center, size = worldAABB(clone)

	local tool = Instance.new("Tool")
	tool.Name = cfg.toolName
	tool.ToolTip = cfg.tip
	tool.CanBeDropped = false
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.38, 0.95, 0.5)
	handle.Transparency = 1
	handle.CanCollide = false
	if cfg.anchorToOriginalHandle then
		handle.CFrame = anchor -- exact op de originele greep
	else
		-- De makers van de QZ-modellen hebben zelf een greep-marker meegeleverd:
		-- het KALE BLOKJE dat in het bronmodel 'Handle' heet (bij de UMP45 heet
		-- een MeshPart óók zo — dat is echte geometrie, niet de marker). Dat
		-- blokje staat exact waar de vuist hoort. Gebruik dat, want gripY/gripZ
		-- waren percentages van de wapenmaat, afgesteld op het pistool: bij de
		-- SMG belandde de Handle daardoor 0.32 te laag en 0.39 te ver naar
		-- achteren, en greep de viewmodel-vuist naast de greep in de lucht.
		local gripMarker
		for _, d in ipairs(clone:GetDescendants()) do
			if d.ClassName == "Part" and d.Name == "Handle" then
				gripMarker = d
			end
		end
		if gripMarker then
			handle.CFrame = CFrame.new(gripMarker.Position)
		else
			handle.CFrame = CFrame.new(center + Vector3.new(0, cfg.gripY * size.Y, cfg.gripZ * size.Z))
		end
	end
	handle.Parent = tool
	local muzzle = Instance.new("Part")
	muzzle.Name = "Muzzle"
	muzzle.Size = Vector3.new(0.1, 0.1, 0.1)
	muzzle.Transparency = 1
	muzzle.CanCollide = false
	muzzle.CFrame = CFrame.new(center + Vector3.new(0, cfg.muzzleY * size.Y, -size.Z / 2 - 0.05))
	muzzle.Parent = tool
	for _, d in ipairs(clone:GetDescendants()) do
		if d:IsA("BasePart") then
			-- Een rig-hulpblokje is ALTIJD een kaal Part. MeshParts en Unions zijn
			-- de echte geometrie van het wapen — die mogen nooit verdwijnen, ook
			-- niet als ze toevallig 'Main' of 'Handle' heten (UMP45!).
			local isHelperBlok = d.ClassName == "Part"
			if d.Name == "Handle" then
				-- binnen een Tool pakt Roblox het deel dat 'Handle' heet; er mag er
				-- dus maar één zijn — die van ons. Hernoemen is altijd nodig.
				d.Name = isHelperBlok and "RigHelper" or "GripMesh"
			end
			if isHelperBlok and (d.Name == "Main" or d.Name == "CAMERA"
				or d.Name == "AimPart" or d.Name == "RigHelper") then
				d.Transparency = 1
			end
			d.Parent = tool
		end
	end
	clone:Destroy()

	-- (verdikken is hierboven al gebeurd, vóór de Handle: zie applyGirth)

	-- lassen (op de definitieve posities) + losmaken van de wereld
	for _, p in ipairs(tool:GetChildren()) do
		if p:IsA("BasePart") then
			p.Anchored = false -- de Handle draagt alles (Tools mogen niet verankerd zijn)
			if p ~= handle then
				local w = Instance.new("WeldConstraint")
				w.Part0 = handle
				w.Part1 = p
				w.Parent = handle
			end
		end
	end
	tool.GripPos = Vector3.new(0, -0.1, 0.05)

	-- VMOffset-stickers: het viewmodel leest hieruit waar elk deel hoort te
	-- zitten t.o.v. de Handle (live posities zijn op de client soms stale bij
	-- wapenwissel — dan bakte het viewmodel een verstrooid wapen!)
	for _, p in ipairs(tool:GetChildren()) do
		if p:IsA("BasePart") and p ~= handle then
			p:SetAttribute("VMOffset", handle.CFrame:ToObjectSpace(p.CFrame))
		end
	end

	for _, d in ipairs(tool:GetDescendants()) do
		if d:IsA("PointLight") then
			d.Range = 3
			d.Brightness = 0.5
		end
	end

	local old = cfg.dest:FindFirstChild(cfg.toolName)
	if old then old:Destroy() end
	tool.Parent = cfg.dest

	-- controle-uitdraai: hoeveel ZICHTBARE geometrie heeft het wapen, en hoe
	-- dik is het? (een "stokje" of een half-onzichtbaar wapen zie je hier meteen)
	local visible, hidden = 0, 0
	local vMin = Vector3.new(math.huge, math.huge, math.huge)
	local vMax = -vMin
	for _, p in ipairs(tool:GetChildren()) do
		if p:IsA("BasePart") and p ~= handle and p ~= muzzle then
			if p.Transparency >= 1 then
				hidden += 1
			else
				visible += 1
				local half = p.Size / 2
				for dx = -1, 1, 2 do for dy = -1, 1, 2 do for dz = -1, 1, 2 do
					local c = p.CFrame:PointToWorldSpace(Vector3.new(half.X * dx, half.Y * dy, half.Z * dz))
					vMin, vMax = vMin:Min(c), vMax:Max(c)
				end end end
			end
		end
	end
	local vs = vMax - vMin
	print(string.format("[Weapons] %-8s zichtbaar=%2d verborgen=%d  zichtbare maat %.2f b × %.2f h × %.2f l",
		cfg.toolName, visible, hidden, vs.X, vs.Y, vs.Z))
end

qzContainer:Destroy()
rayContainer:Destroy()
print("[Weapons] 4 marketplace-wapens herbouwd: Pistol (M1911), SMG (UMP45), Shotgun (pump), RayGun (CoD-replica)")
