-- ViewmodelClient v2: het first-person wapen-systeem (zoals echte FPS-games).
-- Het échte wapen + je échte armen worden voor jou verborgen; in de plaats komt
-- een "viewmodel": nep-armen MET HANDEN + een verkleinde kopie van je wapen,
-- vastgemaakt aan de camera en volledig procedureel geanimeerd:
--   · sway     — zwaait subtiel mee met je muis
--   · bob      — deint op je passen (zwaarder bij sprint), ademt bij stilstand
--   · recoil   — schokt naar achteren bij elk schot
--   · reload   — het wapen kantelt én je LINKERHAND komt in beeld om het
--                magazijn te verwisselen (twee tikjes) en verdwijnt weer
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

local camera = workspace.CurrentCamera

-- wapens die je met twee handen vasthoudt (linkerhand vast op de voorgrip)
local TWO_HANDED = { SMG = true, Shotgun = true }

-- het wapen was te groot in beeld: alles wordt geschaald
local SCALE = 0.45

-- basispositie van het wapen in beeld (rechtsonder, zoals CoD)
local BASE_OFFSET_ONE = CFrame.new(0.45, -0.52, -1.05)
local BASE_OFFSET_TWO = CFrame.new(0.34, -0.5, -1.15)

-- linkerhand-posities (relatief aan de wapen-handle)
local LEFT_PARKED = CFrame.new(-1.6, -1.8, 0.4)                                        -- uit beeld
local LEFT_FOREGRIP = CFrame.new(-0.08, -0.12, -0.75) * CFrame.Angles(0, math.rad(15), math.rad(-20))
local LEFT_MAG = CFrame.new(-0.06, -0.3, -0.32) * CFrame.Angles(math.rad(25), math.rad(15), math.rad(-20))

-- ===================== RIG-STATUS =====================
local rig = nil
local rigParts = {}         -- wapen + rechterarm: { {part, offset} } relatief aan de handle
local leftParts = {}        -- linker onderarm + hand: apart geanimeerd
local currentTool = nil
local toolConnections = {}

local swayCF = CFrame.new()
local bobClock = 0
local recoil = 0
local reloadBlend = 0
local reloadClock = 0
local leftHandCF = LEFT_PARKED

local function clearRig()
	if rig then rig:Destroy() end
	rig = nil
	rigParts = {}
	leftParts = {}
	for _, connection in ipairs(toolConnections) do
		connection:Disconnect()
	end
	toolConnections = {}
	currentTool = nil
end

local function getSkinColor()
	local character = player.Character
	local rightArm = character and (character:FindFirstChild("Right Arm") or character:FindFirstChild("RightHand"))
	return rightArm and rightArm.Color or Color3.fromRGB(234, 184, 146)
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

-- schaal een offset-CFrame: positie mee schalen, rotatie behouden
local function scaleOffset(offset)
	return CFrame.new(offset.Position * SCALE) * offset.Rotation
end

local function buildRig(tool)
	clearRig()
	local handle = tool:FindFirstChild("Handle")
	if not handle then return end

	rig = Instance.new("Model")
	rig.Name = "Viewmodel"
	-- lokaal in workspace (client-objecten repliceren niet — alleen jij ziet dit)
	rig.Parent = workspace

	-- wapen-onderdelen kopiëren, verkleinen en relatief aan de handle vastleggen
	local handleCF = handle.CFrame
	for _, part in ipairs(tool:GetChildren()) do
		if part:IsA("BasePart") and part.Transparency < 1 then
			local clone = part:Clone()
			clone:ClearAllChildren()
			for _, child in ipairs(part:GetChildren()) do
				if child:IsA("PointLight") then
					child:Clone().Parent = clone
				end
			end
			clone.Size = part.Size * SCALE
			clone.Anchored = true
			clone.CanCollide = false
			clone.CanQuery = false
			clone.CanTouch = false
			clone.CastShadow = false
			clone.Parent = rig
			table.insert(rigParts, { part = clone, offset = scaleOffset(handleCF:ToObjectSpace(part.CFrame)) })
		end
	end

	-- ===== rechterarm + hand: houdt de grip écht vast =====
	local skin = getSkinColor()
	local skinDark = Color3.new(skin.R * 0.92, skin.G * 0.92, skin.B * 0.92)

	-- lange arm die vanuit de rechteronderhoek van je scherm naar de grip loopt (zoals echte FPS-armen)
	local rightForearm = makeRigPart({ Name = "RightForearm", Size = Vector3.new(0.26, 0.26, 1.6), Color = skin })
	table.insert(rigParts, { part = rightForearm, offset = CFrame.new(0.3, -0.5, 0.75) * CFrame.Angles(math.rad(-28), math.rad(-14), 0) })

	-- de vuist: palm om de grip + vingers over de voorkant + duim aan de zijkant
	local rightPalm = makeRigPart({ Name = "RightHand", Size = Vector3.new(0.26, 0.34, 0.3), Color = skinDark })
	table.insert(rigParts, { part = rightPalm, offset = CFrame.new(0.05, -0.05, 0.02) })
	local rightFingers = makeRigPart({ Name = "RightFingers", Size = Vector3.new(0.24, 0.3, 0.1), Color = skin })
	table.insert(rigParts, { part = rightFingers, offset = CFrame.new(0, -0.06, -0.14) })
	local rightThumb = makeRigPart({ Name = "RightThumb", Size = Vector3.new(0.08, 0.18, 0.08), Color = skin })
	table.insert(rigParts, { part = rightThumb, offset = CFrame.new(-0.12, 0.04, 0.0) * CFrame.Angles(0, 0, math.rad(18)) })

	-- ===== linkerarm + hand: apart geanimeerd (voorgrip of reload) =====
	local leftForearm = makeRigPart({ Name = "LeftForearm", Size = Vector3.new(0.3, 0.3, 0.75), Color = skin })
	table.insert(leftParts, { part = leftForearm, offset = CFrame.new(-0.12, -0.16, 0.42) * CFrame.Angles(math.rad(-18), math.rad(22), 0) })

	local leftHand = makeRigPart({ Name = "LeftHand", Size = Vector3.new(0.28, 0.3, 0.3), Color = skinDark })
	table.insert(leftParts, { part = leftHand, offset = CFrame.new(0, 0, 0) })
	local leftFingers = makeRigPart({ Name = "LeftFingers", Size = Vector3.new(0.22, 0.26, 0.1), Color = skin })
	table.insert(leftParts, { part = leftFingers, offset = CFrame.new(0.1, 0.02, -0.1) })

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
	leftHandCF = TWO_HANDED[tool.Name] and LEFT_FOREGRIP or LEFT_PARKED

	-- recoil-trigger: magazijn telt af = er is geschoten
	local lastMag = tool:GetAttribute("Mag")
	table.insert(toolConnections, tool:GetAttributeChangedSignal("Mag"):Connect(function()
		local newMag = tool:GetAttribute("Mag")
		if lastMag and newMag and newMag < lastMag then
			recoil = 1
		end
		lastMag = newMag
	end))
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
	camera = workspace.CurrentCamera
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

	-- 4) reload: wapen kantelt licht + linkerhand komt het magazijn verwisselen
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
	local idleLeft = TWO_HANDED[currentTool.Name] and LEFT_FOREGRIP or LEFT_PARKED
	local targetLeft = idleLeft
	if reloadBlend > 0.05 then
		-- duidelijke beweging: hand omhoog naar het magazijn → ruk omlaag (mag eruit)
		-- → duw omhoog (nieuwe mag erin) → vasthouden tot het herladen klaar is
		local pull = math.sin(math.clamp(reloadClock * 4, 0, math.pi)) * 0.3
		targetLeft = LEFT_MAG * CFrame.new(0, -pull, 0.04 * pull)
	end
	leftHandCF = leftHandCF:Lerp(targetLeft, math.clamp(deltaTime * 10, 0, 1))

	-- alles plaatsen
	local baseOffset = TWO_HANDED[currentTool.Name] and BASE_OFFSET_TWO or BASE_OFFSET_ONE
	local handleCF = camera.CFrame * baseOffset * swayCF * bobCF * recoilCF * reloadCF
	for _, entry in ipairs(rigParts) do
		entry.part.CFrame = handleCF * entry.offset
	end
	for _, entry in ipairs(leftParts) do
		entry.part.CFrame = handleCF * leftHandCF * entry.offset
	end
end)
