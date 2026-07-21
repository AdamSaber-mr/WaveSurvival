-- ViewmodelClient v3: het first-person wapen-systeem (zoals echte FPS-games).
-- Het échte wapen + je échte armen worden voor jou verborgen; in de plaats komt
-- een "viewmodel": twee lange slanke armen + een verkleinde kopie van je wapen,
-- vastgemaakt aan de camera en volledig procedureel geanimeerd:
--   · sway     — zwaait subtiel mee met je muis
--   · bob      — deint op je passen (zwaarder bij sprint), ademt bij stilstand
--   · recoil   — schokt naar achteren bij elk schot
--   · reload   — het wapen kantelt én je LINKERHAND duikt naar het magazijn
-- v3-lessen (na de marketplace-wapens):
--   · het wapen wordt als "ghost-model" gekloond en met Model:ScaleTo verkleind —
--     zo schalen ook SpecialMesh/Union-onderdelen netjes mee
--   · de SCHOUDERS zitten in CAMERA-ruimte (niet in wapen-ruimte!), net iets
--     achter de lens en buiten beeld — zo komen de armen als lange slanke lijnen
--     het beeld binnen (zoals de referentiefoto) en draaien ze niet raar mee
--     met de wapen-kanteling
-- v4-lessen (gemeten in een echte Play-sessie i.p.v. gegokt):
--   · SCHAAL PER WAPEN. Eén SCALE voor alles kon niet kloppen: de bronmodellen
--     zijn onderling niet even groot, dus de SMG was een speelgoedje terwijl de
--     shotgun bij dezelfde schaal het halve scherm vulde. Zie GRIPS[..].scale.
--   · HAND-OFFSETS IN WAPEN-MAAT. Ze stonden in beeldmaat, dus zodra je SCALE
--     veranderde lieten de handen los van het wapen. Nu worden ze bij het
--     bouwen met de schaal van dát wapen vermenigvuldigd.
--   · De handen zaten sowieso naast de greep, omdat de onzichtbare Handle van
--     het wapen op een geschatte plek stond (zie tools/build-weapons.luau: die
--     gebruikt nu de greep-marker uit het bronmodel).
-- Andere spelers zien gewoon je normale karakter met wapen.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local player = Players.LocalPlayer

-- voorkom dubbel draaien (Script Sync-eigenaardigheid)
if player:GetAttribute("ViewmodelClientHooked") then
	return
end
player:SetAttribute("ViewmodelClientHooked", true)

-- geen muis-pijltje meer: alleen de crosshair
UserInputService.MouseIconEnabled = false

-- BELANGRIJK: nooit één keer opslaan en hergebruiken. Roblox VERVANGT het
-- Camera-object (bij het starten van een ronde, bij respawnen, bij het wisselen
-- tussen Play en Edit). Bleven we aan het oude object hangen, dan bevroor het
-- hele viewmodel op de plek waar je toen keek — het wapen "verdween" dan.
local function getCamera()
	return workspace.CurrentCamera
end

-- Hoe groot het wapen in beeld is. Dit is de STANDAARD; elk wapen mag in GRIPS
-- zijn eigen 'scale' zetten. Dat moet ook wel: de bronmodellen zijn onderling
-- niet even groot, dus één getal voor alles maakte óf de SMG een speelgoedje,
-- óf de shotgun een balk die het halve scherm vulde.
local SCALE = 0.4
-- De handen groeien mee met het wapen, zodat een vuist een vuist om de greep
-- blijft en niet een handschoentje op een groot wapen. (0.4 = de schaal waarop
-- de hand-maten ooit met de hand zijn afgesteld.)
local HAND_REFERENCE = 0.4

-- ===== armen: lang en slank, zoals de referentiefoto =====
local ARM_THICKNESS = 0.13
local SLEEVE_THICKNESS = 0.17
-- schouder-ankers in CAMERA-ruimte (x=rechts, y=omhoog, z=achter de lens).
-- Ze hangen laag en nét buiten/achter het beeld, zodat alleen de lange
-- onderarm zichtbaar het beeld in steekt.
-- LES: stond de schouder te ver opzij en te dicht op de lens (x=-0.8, z=0.12),
-- dan schoot de arm vlak langs de camera en blies het perspectief hem op tot
-- een reuzenplank dwars door het beeld. Verder naar achteren (grotere z) knipt
-- de camera het bovenste stuk weg: je ziet alleen nog de onderarm.
local RIGHT_SHOULDER = Vector3.new(0.45, -0.85, 0.55)
local LEFT_SHOULDER = Vector3.new(-0.42, -0.90, 0.55)

-- ===== per-wapen griphouding =====
-- Een pistool houd je anders vast dan een shotgun. Alle hand-offsets zijn
-- relatief aan de wapen-Handle (die zit ín de greep van het wapen):
--   base      = waar het wapen in beeld hangt (relatief aan de CAMERA)
--   rightHand = rechtervuist om de greep
--   leftIdle  = linkerhand in rust (steun-kom / voorgrip / pump)
--   leftMag   = waar de linkerhand naartoe duikt tijdens het herladen
--
-- BELANGRIJK: de drie hand-offsets staan in WAPEN-maat (schaal 1), niet in
-- beeldmaat. Ze worden bij het bouwen met SCALE vermenigvuldigd. Daardoor
-- blijven de handen op het wapen plakken als je SCALE verandert — vroeger
-- stonden hier vaste getallen en liet elke hand los zodra het wapen groeide.
-- 'base' schaalt NIET mee: dat is camera-ruimte, niet wapen-ruimte.
local GRIPS = {
	Pistol = {
		base = CFrame.new(0.28, -0.5, -1.15) * CFrame.Angles(math.rad(2), math.rad(4), math.rad(2)),
		rightHand = CFrame.new(0, -0.25, 0.08),
		leftIdle = CFrame.new(-0.25, -0.5, 0.25) * CFrame.Angles(0, math.rad(15), math.rad(42)),
		leftMag = CFrame.new(-0.15, -1.25, 0.13) * CFrame.Angles(math.rad(22), math.rad(10), math.rad(-16)),
	},
	SMG = {
		-- de UMP45 was op 0.4 een speelgoedje dat rechtsboven zweefde
		scale = 0.62,
		base = CFrame.new(0.22, -0.30, -1.40) * CFrame.Angles(math.rad(2), math.rad(6), math.rad(2)),
		-- gemeten: de Handle zit nu ín de greep, met de Trigger op y=0.08 z=-0.23
		rightHand = CFrame.new(0.01, -0.10, 0.03),
		leftIdle = CFrame.new(0.01, 0.02, -1.07) * CFrame.Angles(0, math.rad(6), math.rad(-14)),
		leftMag = CFrame.new(0.01, -0.19, -0.68) * CFrame.Angles(math.rad(24), math.rad(10), math.rad(-18)),
	},
	Shotgun = {
		-- dit model is van zichzelf al fors; groter maken vult het halve scherm
		scale = 0.42,
		base = CFrame.new(0.36, -0.48, -1.29) * CFrame.Angles(math.rad(2), math.rad(6), math.rad(2)),
		rightHand = CFrame.new(0, -0.10, 0.03),
		-- gemeten in Studio: de Pump zit op z=-1.34, y=0.13
		leftIdle = CFrame.new(0, 0.13, -1.34) * CFrame.Angles(0, math.rad(5), math.rad(-10)),
		leftMag = CFrame.new(0, -0.05, -0.75) * CFrame.Angles(math.rad(20), math.rad(8), math.rad(-14)),
	},
	RayGun = {
		-- kortste model van de vier (1.95 zichtbaar tegen 2.71 van de SMG), dus
		-- hij heeft de grootste schaal nodig om even fors in beeld te staan
		scale = 0.72,
		-- recht vooruit, zelfde lichte hoek als de andere wapens (Adams voorkeur:
		-- schuin gedraaid vond hij niet mooi, ook al zie je dan de meter beter)
		base = CFrame.new(0.449, -1.000, -1.878) * CFrame.Angles(math.rad(2), math.rad(4), math.rad(2)),
		-- gemeten: de greep loopt van y=-0.23 tot y=+0.30 rond z=+0.22. De
		-- linkerhand hing daar 0.43 stud naast in de lucht.
		rightHand = CFrame.new(0.02, -0.12, 0.20),
		leftIdle = CFrame.new(-0.16, -0.30, 0.26) * CFrame.Angles(0, math.rad(15), math.rad(42)),
		leftMag = CFrame.new(-0.12, -0.85, 0.22) * CFrame.Angles(math.rad(22), math.rad(10), math.rad(-16)),
	},
}
local DEFAULT_GRIP = GRIPS.Pistol

-- wapen-maat → beeldmaat: alleen de POSITIE schaalt, de draaiing blijft
local function toViewScale(cf, s)
	return CFrame.new(cf.Position * s) * (cf - cf.Position)
end
local function scaleGrip(grip)
	local s = grip.scale or SCALE
	return {
		scale = s,
		hand = s / HAND_REFERENCE,
		base = grip.base, -- camera-ruimte: niet meeschalen
		rightHand = toViewScale(grip.rightHand, s),
		leftIdle = toViewScale(grip.leftIdle, s),
		leftMag = toViewScale(grip.leftMag, s),
	}
end

-- ===================== RIG-STATUS =====================
local rig = nil
local rigParts = {}         -- wapen-delen: { {part, offset} } relatief aan de handle
local leftParts = {}        -- linkerhand: apart geanimeerd (steun/voorgrip/reload)
local armParts = nil        -- { rArm, rSleeve, lArm, lSleeve }: elke frame gespannen
local currentTool = nil
local currentGrip = scaleGrip(DEFAULT_GRIP)
local toolConnections = {}

local swayCF = CFrame.new()
local bobClock = 0
local recoil = 0
local reloadBlend = 0
local reloadClock = 0
local leftHandCF = CFrame.new()

-- ===================== HULZEN =====================
-- bij elk schot wipt er rechts een leeg hulsje uit dat op de grond stuitert.
-- Puur lokaal (alleen jij ziet je eigen hulzen) — kost bijna niks.
local casingRng = Random.new()
local function ejectCasing()
	local isShotgun = currentTool and currentTool.Name == "Shotgun"
	local casing = Instance.new("Part")
	casing.Name = "Casing"
	casing.Shape = Enum.PartType.Cylinder
	casing.Size = isShotgun and Vector3.new(0.3, 0.11, 0.11) or Vector3.new(0.22, 0.07, 0.07)
	casing.Color = isShotgun and Color3.fromRGB(190, 50, 50) or Color3.fromRGB(205, 165, 85)
	casing.Material = isShotgun and Enum.Material.SmoothPlastic or Enum.Material.Metal
	casing.CanCollide = true
	casing.CanQuery = false
	casing.CanTouch = false
	-- start naast de loop (rechts van het wapen in beeld)
	local camCF = getCamera().CFrame
	casing.CFrame = camCF * CFrame.new(0.5, -0.4, -1)
	-- wipt naar rechtsboven weg, met een flinke tol erin
	casing.AssemblyLinearVelocity = camCF.RightVector * casingRng:NextNumber(4, 7)
		+ camCF.UpVector * casingRng:NextNumber(3, 5)
		+ camCF.LookVector * casingRng:NextNumber(-1, 1)
	casing.AssemblyAngularVelocity = Vector3.new(
		casingRng:NextNumber(-25, 25), casingRng:NextNumber(-25, 25), casingRng:NextNumber(-25, 25))
	casing.Parent = workspace -- door de client gemaakt = alleen jij ziet hem
	task.delay(2, function()
		if casing.Parent then
			for step = 1, 6 do
				casing.Transparency = step / 6
				task.wait(0.05)
			end
			casing:Destroy()
		end
	end)
end

local function clearRig()
	if rig then rig:Destroy() end
	rig = nil
	rigParts = {}
	leftParts = {}
	armParts = nil
	for _, connection in ipairs(toolConnections) do
		connection:Disconnect()
	end
	toolConnections = {}
	currentTool = nil
end

-- huidkleur van je echte arm + shirtkleur van je torso (voor de mouwen)
local function getBodyColors()
	local character = player.Character
	local rightArm = character and (character:FindFirstChild("Right Arm") or character:FindFirstChild("RightHand"))
	local torso = character and (character:FindFirstChild("Torso") or character:FindFirstChild("UpperTorso"))
	local skin = rightArm and rightArm.Color or Color3.fromRGB(234, 184, 146)
	local sleeve = torso and torso.Color or Color3.fromRGB(46, 60, 98)
	return skin, sleeve
end

local function makeRigPart(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Material = Enum.Material.SmoothPlastic
	for k, v in pairs(props) do p[k] = v end
	p.Parent = rig
	return p
end

local function buildRig(tool)
	clearRig()
	local handle = tool:FindFirstChild("Handle")
	if not handle then return end

	rig = Instance.new("Model")
	rig.Name = "Viewmodel"
	-- lokaal in workspace (client-objecten repliceren niet — alleen jij ziet dit)
	rig.Parent = workspace

	-- griphouding van dít wapen, al omgerekend naar beeldmaat
	local grip = scaleGrip(GRIPS[tool.Name] or DEFAULT_GRIP)

	-- ===== wapen als ghost-model klonen en uniform verkleinen =====
	-- ScaleTo schaalt ALLES netjes mee (ook SpecialMesh/Union-delen van de
	-- marketplace-wapens); daarna leggen we elk deel vast relatief aan de handle.
	-- BELANGRIJK: we vertrouwen NIET op de live posities van het echte wapen —
	-- die kunnen op de client nog "stale" zijn als je net van wapen wisselt
	-- (halve replicatie = verstrooide viewmodel!). In plaats daarvan leest elke
	-- clone zijn positie uit de VMOffset-sticker die bij het bouwen is gezet.
	local ghost = Instance.new("Model")
	local ghostHandle = nil
	local cloneSources = {}
	for _, part in ipairs(tool:GetChildren()) do
		if part:IsA("BasePart") then
			local clone = part:Clone()
			for _, child in ipairs(clone:GetChildren()) do
				-- meshes en lampjes houden, de rest (lasjes e.d.) weg
				if not (child:IsA("DataModelMesh") or child:IsA("PointLight")) then
					child:Destroy()
				end
			end
			clone.Anchored = true
			clone.CanCollide = false
			clone.CanQuery = false
			clone.CanTouch = false
			clone.CastShadow = false
			clone.Massless = true
			clone.Parent = ghost
			cloneSources[clone] = part
			if part == handle then ghostHandle = clone end
		end
	end
	if not ghostHandle then
		ghost:Destroy()
		return
	end
	-- poses herstellen vanaf de stickers (replicatie-proof), handle op de oorsprong
	local liveHandleCF = handle.CFrame
	ghostHandle.CFrame = CFrame.new()
	for clone, source in pairs(cloneSources) do
		if clone ~= ghostHandle then
			local stored = source:GetAttribute("VMOffset")
			if typeof(stored) == "CFrame" then
				clone.CFrame = stored
			else
				-- geen sticker (oud wapen)? dan toch de live-foto als noodgreep
				clone.CFrame = liveHandleCF:ToObjectSpace(source.CFrame)
			end
		end
	end
	ghost:ScaleTo(grip.scale)
	local ghostHandleCF = ghostHandle.CFrame
	local startCF = getCamera().CFrame * grip.base
	for _, clone in ipairs(ghost:GetChildren()) do
		if clone:IsA("BasePart") then
			local offset = ghostHandleCF:ToObjectSpace(clone.CFrame)
			if clone.Transparency < 1 then
				clone.CFrame = startCF * offset -- meteen goed neerzetten (geen flits)
				clone.Parent = rig
				table.insert(rigParts, { part = clone, offset = offset })
			end
		end
	end
	ghost:Destroy()

	local skin, sleeveColor = getBodyColors()
	local skinDark = Color3.new(skin.R * 0.92, skin.G * 0.92, skin.B * 0.92)

	-- rechterhand: vuist om de greep + vingers eromheen (klein en plat)
	local rightHand = makeRigPart({ Name = "RightHand", Size = Vector3.new(0.16, 0.16, 0.2) * grip.hand, Color = skinDark })
	table.insert(rigParts, { part = rightHand, offset = grip.rightHand })
	local rightFingers = makeRigPart({ Name = "RightFingers", Size = Vector3.new(0.14, 0.15, 0.06) * grip.hand, Color = skin })
	table.insert(rigParts, { part = rightFingers, offset = grip.rightHand * CFrame.new(Vector3.new(0, -0.02, -0.12) * grip.hand) })

	-- linkerhand: vuist + vingers + duim, apart geanimeerd (steun/voorgrip/reload)
	local leftHand = makeRigPart({ Name = "LeftHand", Size = Vector3.new(0.18, 0.18, 0.22) * grip.hand, Color = skinDark })
	table.insert(leftParts, { part = leftHand, offset = CFrame.new() })
	local leftFingers = makeRigPart({ Name = "LeftFingers", Size = Vector3.new(0.15, 0.17, 0.07) * grip.hand, Color = skin })
	table.insert(leftParts, { part = leftFingers, offset = CFrame.new(Vector3.new(0.08, 0.04, -0.12) * grip.hand) * CFrame.Angles(0, 0, math.rad(10)) })
	local leftThumb = makeRigPart({ Name = "LeftThumb", Size = Vector3.new(0.06, 0.11, 0.06) * grip.hand, Color = skin })
	table.insert(leftParts, { part = leftThumb, offset = CFrame.new(Vector3.new(-0.07, 0.05, 0.02) * grip.hand) * CFrame.Angles(0, 0, math.rad(-14)) })

	-- armen + mouwen: elke frame opnieuw gespannen tussen schouder (camera-
	-- ruimte) en hand — lengte maakt niet uit, we maken ze ruim lang genoeg
	armParts = {
		rArm = makeRigPart({ Name = "RightArm", Size = Vector3.new(ARM_THICKNESS, ARM_THICKNESS, 1), Color = skin }),
		rSleeve = makeRigPart({ Name = "RightSleeve", Size = Vector3.new(SLEEVE_THICKNESS, SLEEVE_THICKNESS, 1), Color = sleeveColor }),
		lArm = makeRigPart({ Name = "LeftArm", Size = Vector3.new(ARM_THICKNESS, ARM_THICKNESS, 1), Color = skin }),
		lSleeve = makeRigPart({ Name = "LeftSleeve", Size = Vector3.new(SLEEVE_THICKNESS, SLEEVE_THICKNESS, 1), Color = sleeveColor }),
	}

	-- rig-lampje: anders is het wapen 's nachts zwart-op-zwart
	local lightAnchor = makeRigPart({ Name = "RigLight", Size = Vector3.new(0.1, 0.1, 0.1), Transparency = 1 })
	table.insert(rigParts, { part = lightAnchor, offset = CFrame.new(0.15, 0.4, -0.3) })
	local rigLight = Instance.new("PointLight")
	rigLight.Color = Color3.fromRGB(255, 235, 210)
	rigLight.Range = 4.5
	rigLight.Brightness = 0.85
	rigLight.Shadows = false
	rigLight.Parent = lightAnchor

	currentTool = tool
	currentGrip = grip
	leftHandCF = grip.leftIdle

	-- recoil-trigger: magazijn telt af = er is geschoten
	local lastMag = tool:GetAttribute("Mag")
	table.insert(toolConnections, tool:GetAttributeChangedSignal("Mag"):Connect(function()
		local newMag = tool:GetAttribute("Mag")
		if lastMag and newMag and newMag < lastMag then
			recoil = 1
			ejectCasing()
		end
		lastMag = newMag
	end))
end

-- arm + mouw spannen tussen schouder (camera-ruimte) en pols (wereld-positie)
local function stretchArm(arm, sleeve, shoulderCam, wristWorld, sleeveFraction)
	local camCF = getCamera().CFrame
	local wristCam = camCF:ToObjectSpace(CFrame.new(wristWorld)).Position
	local delta = wristCam - shoulderCam
	local length = delta.Magnitude
	if length < 0.05 then return end
	arm.Size = Vector3.new(ARM_THICKNESS, ARM_THICKNESS, length)
	arm.CFrame = camCF * CFrame.lookAt(shoulderCam + delta / 2, wristCam)
	local sleeveLength = length * sleeveFraction
	sleeve.Size = Vector3.new(SLEEVE_THICKNESS, SLEEVE_THICKNESS, sleeveLength)
	sleeve.CFrame = camCF * CFrame.lookAt(shoulderCam + delta.Unit * (sleeveLength / 2), wristCam)
end

-- ===================== EQUIP/UNEQUIP VOLGEN =====================
local function watchCharacter(character)
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") and Config.Weapons[child.Name] then
			buildRig(child)
		end
	end)
	character.ChildRemoved:Connect(function(child)
		if child == currentTool then
			clearRig()
		end
	end)
	local equipped = character:FindFirstChildOfClass("Tool")
	if equipped and Config.Weapons[equipped.Name] then
		buildRig(equipped)
	end
end
if player.Character then watchCharacter(player.Character) end
player.CharacterAdded:Connect(function(character)
	clearRig()
	watchCharacter(character)
end)

-- ===================== DE ANIMATIE-MOTOR =====================
RunService:BindToRenderStep("SpacelandViewmodel", Enum.RenderPriority.Camera.Value + 1, function(deltaTime)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")

	-- het échte wapen + je échte armen verbergen (elke frame, de camera zet ze terug)
	if currentTool and currentTool.Parent == character then
		for _, part in ipairs(currentTool:GetChildren()) do
			if part:IsA("BasePart") then
				part.LocalTransparencyModifier = 1
			end
		end
		for _, armName in ipairs({ "Right Arm", "Left Arm", "RightUpperArm", "RightLowerArm", "RightHand", "LeftUpperArm", "LeftLowerArm", "LeftHand" }) do
			local arm = character:FindFirstChild(armName)
			if arm then
				arm.LocalTransparencyModifier = 1
			end
		end
	end

	if not rig or not currentTool or not humanoid or humanoid.Health <= 0 then
		return
	end

	-- 1) sway
	local mouseDelta = UserInputService:GetMouseDelta()
	local targetSway = CFrame.Angles(
		math.clamp(-mouseDelta.Y * 0.0012, -0.06, 0.06),
		math.clamp(-mouseDelta.X * 0.0012, -0.08, 0.08),
		math.clamp(-mouseDelta.X * 0.0008, -0.04, 0.04)
	)
	swayCF = swayCF:Lerp(targetSway, math.clamp(deltaTime * 10, 0, 1))

	-- 2) bob
	local speed = humanoid.MoveDirection.Magnitude * humanoid.WalkSpeed
	local bobCF
	if speed > 1 then
		local sprinting = humanoid.WalkSpeed > 18
		local frequency = sprinting and 12 or 8.5
		local amplitude = sprinting and 0.045 or 0.025
		bobClock += deltaTime * frequency
		bobCF = CFrame.new(math.sin(bobClock * 0.5) * amplitude * 1.6, math.abs(math.sin(bobClock)) * amplitude, 0)
			* CFrame.Angles(0, 0, math.sin(bobClock * 0.5) * amplitude * 0.6)
	else
		bobClock = 0
		bobCF = CFrame.new(0, math.sin(os.clock() * 1.6) * 0.01, 0)
	end

	-- 3) recoil
	recoil = math.max(recoil - deltaTime * 7, 0)
	local recoilCF = CFrame.new(0, recoil * 0.05, recoil * 0.18) * CFrame.Angles(math.rad(recoil * 5), 0, 0)

	-- 4) reload: wapen kantelt licht + linkerhand duikt naar het magazijn
	local reloading = currentTool:GetAttribute("Reloading") == true
	reloadBlend = math.clamp(reloadBlend + (reloading and 1 or -1) * deltaTime * 4.5, 0, 1)
	if reloading then
		reloadClock += deltaTime
	else
		reloadClock = 0
	end
	-- het wapen kantelt naar je toe zodat je het magazijn ziet (CoD-stijl)
	local reloadCF = CFrame.new(-0.05 * reloadBlend, -0.1 * reloadBlend, 0.05 * reloadBlend)
		* CFrame.Angles(math.rad(-10 * reloadBlend), math.rad(12 * reloadBlend), math.rad(-32 * reloadBlend))

	-- linkerhand-doel bepalen
	local idleLeft = currentGrip.leftIdle
	local targetLeft = idleLeft
	if reloadBlend > 0.05 then
		-- duidelijke beweging: hand omhoog naar het magazijn → ruk omlaag (mag eruit)
		-- → duw omhoog (nieuwe mag erin) → vasthouden tot het herladen klaar is
		local pull = math.sin(math.clamp(reloadClock * 4, 0, math.pi)) * 0.3
		targetLeft = currentGrip.leftMag * CFrame.new(0, -pull, 0.04 * pull)
	end
	leftHandCF = leftHandCF:Lerp(targetLeft, math.clamp(deltaTime * 10, 0, 1))

	-- alles plaatsen
	local baseOffset = currentGrip.base
	local handleCF = getCamera().CFrame * baseOffset * swayCF * bobCF * recoilCF * reloadCF
	for _, entry in ipairs(rigParts) do
		entry.part.CFrame = handleCF * entry.offset
	end
	for _, entry in ipairs(leftParts) do
		entry.part.CFrame = handleCF * leftHandCF * entry.offset
	end

	-- armen: elke frame gespannen tussen de camera-schouders en de handen
	if armParts then
		local rightWristWorld = (handleCF * currentGrip.rightHand * CFrame.new(Vector3.new(0.03, -0.06, 0.13) * currentGrip.hand)).Position
		stretchArm(armParts.rArm, armParts.rSleeve, RIGHT_SHOULDER, rightWristWorld, 0.78)
		local leftWristWorld = (handleCF * leftHandCF * CFrame.new(Vector3.new(-0.02, -0.05, 0.11) * currentGrip.hand)).Position
		stretchArm(armParts.lArm, armParts.lSleeve, LEFT_SHOULDER, leftWristWorld, 0.75)
	end
end)
