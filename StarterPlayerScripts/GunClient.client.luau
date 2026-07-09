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
local mouse = player:GetMouse()

-- RICHT-FIX: je eigen poppetje (inclusief zwaaiende armen en wapen) is
-- onzichtbaar voor de muis-richtstraal — anders "raak" je jezelf tijdens het rennen
-- en vliegen je kogels alle kanten op.
mouse.TargetFilter = player.Character
player.CharacterAdded:Connect(function(character)
	mouse.TargetFilter = character
end)

local function hookTool(tool)
	if not tool:IsA("Tool") then return end
	local weaponConfig = Config.Weapons[tool.Name]
	if not weaponConfig then return end
	if tool:GetAttribute("ClientHooked") then return end
	tool:SetAttribute("ClientHooked", true)

	local holding = false

	tool.Activated:Connect(function()
		holding = true
		while holding and tool.Parent == player.Character do
			local mag = tool:GetAttribute("Mag")
			if mag ~= nil and mag <= 0 then
				-- klik op een leeg magazijn → automatisch herladen
				reloadEvent:FireServer()
				break
			end
			fireEvent:FireServer(mouse.Hit.Position)
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
