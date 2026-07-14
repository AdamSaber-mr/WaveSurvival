-- SprintClient: het first-person beweeg-gevoel.
--  · Shift ingedrukt = sprinten (1.45x je huidige snelheid — werkt dus ook mét Stamin-Up)
--  · FOV-kick: het beeld zoomt subtiel uit tijdens het sprinten (snelheidsgevoel)
--  · camera-bob: de camera deint zachtjes mee met je passen, zwaarder bij sprint

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- voorkom dubbel draaien (Script Sync-eigenaardigheid)
if player:GetAttribute("SprintClientHooked") then
	return
end
player:SetAttribute("SprintClientHooked", true)

local SPRINT_MULTIPLIER = 1.45
local WALK_FOV = 70
local SPRINT_FOV = 78

local camera = workspace.CurrentCamera
local sprinting = false
local baseWalkSpeed = nil

local function getHumanoid()
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

local function startSprint()
	if sprinting then return end
	local humanoid = getHumanoid()
	if not humanoid or humanoid.Health <= 0 then return end
	if player:GetAttribute("Spectator") == true then return end
	sprinting = true
	baseWalkSpeed = humanoid.WalkSpeed
	humanoid.WalkSpeed = baseWalkSpeed * SPRINT_MULTIPLIER
	TweenService:Create(camera, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FieldOfView = SPRINT_FOV }):Play()
end

local function stopSprint()
	if not sprinting then return end
	sprinting = false
	local humanoid = getHumanoid()
	if humanoid and baseWalkSpeed then
		-- terug naar de basis (tenzij de server hem intussen wijzigde, bijv. een perk)
		if math.abs(humanoid.WalkSpeed - baseWalkSpeed * SPRINT_MULTIPLIER) < 0.5 then
			humanoid.WalkSpeed = baseWalkSpeed
		end
	end
	baseWalkSpeed = nil
	TweenService:Create(camera, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { FieldOfView = WALK_FOV }):Play()
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		startSprint()
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		stopSprint()
	end
end)

-- sprint stopt netjes bij dood/respawn
player.CharacterAdded:Connect(function()
	sprinting = false
	baseWalkSpeed = nil
	camera = workspace.CurrentCamera
	camera.FieldOfView = WALK_FOV
end)

-- camera-bob: zachte deining op het ritme van je passen
local bobClock = 0
RunService.RenderStepped:Connect(function(deltaTime)
	local humanoid = getHumanoid()
	if not humanoid or humanoid.Health <= 0 then return end
	local speed = humanoid.MoveDirection.Magnitude * humanoid.WalkSpeed
	if speed > 1 then
		local frequency = sprinting and 11 or 8
		local amplitude = sprinting and 0.14 or 0.07
		bobClock += deltaTime * frequency
		humanoid.CameraOffset = Vector3.new(
			math.sin(bobClock * 0.5) * amplitude * 0.6,
			math.abs(math.sin(bobClock)) * amplitude,
			0
		)
	else
		bobClock = 0
		humanoid.CameraOffset = humanoid.CameraOffset:Lerp(Vector3.zero, 0.15)
	end
end)
