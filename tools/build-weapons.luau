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

-- assets laden en meteen verankeren (anders valt het pack kapot op de baseplate)
local function loadAsset(assetId)
	local container = InsertService:LoadAsset(assetId)
	for _, d in ipairs(container:GetDescendants()) do
		if d:IsA("BasePart") then d.Anchored = true end
	end
	return container
end
local qzContainer = loadAsset(5722821580)
local qzPack = qzContainer:FindFirstChildOfClass("Model")
local rayContainer = loadAsset(434887296)
local raySource = rayContainer:FindFirstChild("RAY GUN", true)

-- widen = extra verdikking op de breedte-as (Adams feedback: QZ-wapens zijn
-- van zichzelf erg dun; shotgun en raygun moeten dik/stoer ogen)
local CONFIG = {
	{ toolName = "Pistol", src = qzPack:FindFirstChild("M1911_1"),
	  rot = CFrame.Angles(0, math.rad(90), 0), targetLength = 1.9, widen = 1,
	  gripY = -0.18, gripZ = 0.30, muzzleY = 0.34, tip = "Pistol", dest = sp },
	{ toolName = "SMG", src = qzPack:FindFirstChild("UMP45"),
	  rot = CFrame.Angles(0, math.rad(90), 0), targetLength = 2.9, widen = 1,
	  gripY = -0.24, gripZ = 0.26, muzzleY = 0.15, tip = "SMG — hold to fire", dest = weaponsF },
	{ toolName = "Shotgun", src = qzPack:FindFirstChild("Shotgun"),
	  rot = CFrame.fromMatrix(Vector3.zero, Vector3.new(0, 1, 0), Vector3.new(0, 0, -1), Vector3.new(-1, 0, 0)),
	  targetLength = 4.3, widen = 1.7,
	  gripY = -0.08, gripZ = 0.30, muzzleY = 0.30, tip = "Shotgun — devastating up close", dest = weaponsF },
	{ toolName = "RayGun", src = raySource,
	  rot = CFrame.new(), targetLength = 3.6, widen = 1.5,
	  gripY = -0.22, gripZ = 0.30, muzzleY = 0.08, tip = "Ray Gun — the jackpot", dest = weaponsF,
	  renameHandle = true, anchorToOriginalHandle = true },
}

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
		handle.CFrame = CFrame.new(center + Vector3.new(0, cfg.gripY * size.Y, cfg.gripZ * size.Z))
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
			-- rig-hulpblokjes van het bronmodel verbergen/hernoemen
			if d.Name == "Main" or d.Name == "CAMERA" or d.Name == "AimPart" then
				d.Transparency = 1
			end
			if d.Name == "Handle" then
				d.Name = "RigHelper"
				d.Transparency = 1
			end
			d.Parent = tool
		end
	end
	clone:Destroy()

	-- verdikken: breedte-as (wereld-X, loop ligt op -Z) per deel oprekken
	-- LET OP: dit moet VÓÓR het lassen — lasjes onthouden de posities van
	-- het moment van maken en zouden de verdikking terugtrekken
	if cfg.widen and cfg.widen ~= 1 then
		local centerX = handle.Position.X
		for _, p in ipairs(tool:GetChildren()) do
			if p:IsA("BasePart") and p ~= handle and p ~= muzzle then
				local v = p.CFrame:VectorToObjectSpace(Vector3.new(1, 0, 0))
				local ax, ay, az = math.abs(v.X), math.abs(v.Y), math.abs(v.Z)
				local s = p.Size
				if ax >= ay and ax >= az then
					p.Size = Vector3.new(s.X * cfg.widen, s.Y, s.Z)
				elseif ay >= ax and ay >= az then
					p.Size = Vector3.new(s.X, s.Y * cfg.widen, s.Z)
				else
					p.Size = Vector3.new(s.X, s.Y, s.Z * cfg.widen)
				end
				for _, child in ipairs(p:GetChildren()) do
					if child:IsA("SpecialMesh") or child:IsA("BlockMesh") or child:IsA("CylinderMesh") then
						local ms = child.Scale
						if ax >= ay and ax >= az then
							child.Scale = Vector3.new(ms.X * cfg.widen, ms.Y, ms.Z)
						elseif ay >= ax and ay >= az then
							child.Scale = Vector3.new(ms.X, ms.Y * cfg.widen, ms.Z)
						else
							child.Scale = Vector3.new(ms.X, ms.Y, ms.Z * cfg.widen)
						end
					end
				end
				local pos = p.Position
				p.Position = Vector3.new(centerX + (pos.X - centerX) * cfg.widen, pos.Y, pos.Z)
			end
		end
	end

	-- nu pas lassen (op de definitieve posities) + losmaken van de wereld
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
end

qzContainer:Destroy()
rayContainer:Destroy()
print("[Weapons] 4 marketplace-wapens herbouwd: Pistol (M1911), SMG (UMP45), Shotgun (pump), RayGun (CoD-replica)")
