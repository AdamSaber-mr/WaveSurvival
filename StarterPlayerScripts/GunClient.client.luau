-- GunClient: de trigger op jouw tv-scherm.
-- Als je klikt met het pistool in de hand, sturen we via de walkietalkie
-- alleen een verzoek ("schiet richting dit punt!") — de server beslist de rest.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local fireEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("FireWeapon")
local mouse = player:GetMouse()

local function hookTool(tool)
	if not tool:IsA("Tool") or tool.Name ~= "Pistol" then return end
	-- voorkom dubbele verbindingen als de tool tussen rugzak en hand wisselt
	if tool:GetAttribute("ClientHooked") then return end
	tool:SetAttribute("ClientHooked", true)

	tool.Activated:Connect(function()
		fireEvent:FireServer(mouse.Hit.Position)
	end)
end

local function hookContainer(container)
	for _, child in ipairs(container:GetChildren()) do
		hookTool(child)
	end
	container.ChildAdded:Connect(hookTool)
end

-- de tool kan in de rugzak zitten (Backpack) of al in de hand (Character)
hookContainer(player:WaitForChild("Backpack"))
if player.Character then
	hookContainer(player.Character)
end
player.CharacterAdded:Connect(function(character)
	hookContainer(player:WaitForChild("Backpack"))
	hookContainer(character)
end)
