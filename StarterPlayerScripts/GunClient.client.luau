-- GunClient: de trigger op jouw tv-scherm — voor élk wapen uit de knoppenkast.
-- Klik = schot (SMG: vasthouden = blijven vuren). R = herladen.
-- Leeg magazijn? Dan vraagt hij automatisch een reload aan.
-- De server beslist altijd of het schot/de reload écht telt.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local player = Players.LocalPlayer

-- voorkom dubbel draaien (Script Sync-eigenaardigheid)
if player:GetAttribute("GunClientHooked") then
	return
end
player:SetAttribute("GunClientHooked", true)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local fireEvent = remotes:WaitForChild("FireWeapon")
local reloadEvent = remotes:WaitForChild("ReloadWeapon")

-- RICHT-FIX v2: niet meer richten via de muis. De muis rekent namelijk met de
-- Roblox-bovenbalk mee en wees daardoor nét een stukje te hoog — kogels vlogen
-- boven de crosshair langs. Nu schieten we zelf een straal door het EXACTE
-- midden van het scherm: precies het punt waar de crosshair getekend wordt.
-- (je eigen poppetje wordt overgeslagen; viewmodel/hulzen hebben CanQuery=false
-- en zijn dus sowieso onzichtbaar voor de straal)
local function aimTarget()
	local camera = workspace.CurrentCamera
	local viewport = camera.ViewportSize
	local ray = camera:ViewportPointToRay(viewport.X / 2, viewport.Y / 2)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { player.Character }
	local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
	return result and result.Position or (ray.Origin + ray.Direction * 1000)
end

local function hookTool(tool)
	if not tool:IsA("Tool") then return end
	local weaponConfig = Config.Weapons[tool.Name]
	if not weaponConfig then return end
	if tool:GetAttribute("ClientHooked") then return end
	tool:SetAttribute("ClientHooked", true)

	local holding = false

	-- ===== wapen-animaties (lokaal, puur visueel) =====
	local baseGrip = tool.Grip

	-- terugslag: het wapen schokt kort naar achteren/omhoog bij elk schot
	local function recoilKick()
		tool.Grip = baseGrip * CFrame.new(0, 0.03, 0.16) * CFrame.Angles(math.rad(5), 0, 0)
		task.delay(0.06, function()
			if tool.Parent and not tool:GetAttribute("Reloading") then
				tool.Grip = baseGrip
			end
		end)
	end

	-- reload-dip: het wapen kantelt omlaag zolang je herlaadt
	tool:GetAttributeChangedSignal("Reloading"):Connect(function()
		if not tool.Parent then return end
		if tool:GetAttribute("Reloading") then
			tool.Grip = baseGrip * CFrame.new(0, -0.35, 0.1) * CFrame.Angles(math.rad(-35), math.rad(8), 0)
		else
			tool.Grip = baseGrip
		end
	end)

	tool.Activated:Connect(function()
		holding = true
		while holding and tool.Parent == player.Character do
			local mag = tool:GetAttribute("Mag")
			if mag ~= nil and mag <= 0 then
				-- klik op een leeg magazijn → automatisch herladen
				reloadEvent:FireServer()
				break
			end
			fireEvent:FireServer(aimTarget())
			recoilKick()
			if not weaponConfig.Auto then
				break
			end
			task.wait(weaponConfig.FireCooldown)
		end
	end)

	tool.Deactivated:Connect(function()
		holding = false
	end)

	tool.Unequipped:Connect(function()
		holding = false
	end)
end

local function hookContainer(container)
	for _, child in ipairs(container:GetChildren()) do
		hookTool(child)
	end
	container.ChildAdded:Connect(hookTool)
end

hookContainer(player:WaitForChild("Backpack"))
if player.Character then
	hookContainer(player.Character)
end
player.CharacterAdded:Connect(function(character)
	hookContainer(player:WaitForChild("Backpack"))
	hookContainer(character)
end)

-- R = herladen (alleen als je een wapen uit de knoppenkast vasthoudt)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.R then
		local character = player.Character
		local tool = character and character:FindFirstChildOfClass("Tool")
		if tool and Config.Weapons[tool.Name] then
			reloadEvent:FireServer()
		end
	end
end)
