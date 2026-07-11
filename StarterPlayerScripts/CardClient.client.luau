-- CardClient: druk F om je Fate-kaart te activeren.
-- De server beslist of het mag (kaart aanwezig + nog niet gebruikt).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer

-- voorkom dubbel draaien (Script Sync-eigenaardigheid)
if player:GetAttribute("CardClientHooked") then
	return
end
player:SetAttribute("CardClientHooked", true)

local useCardEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("UseCard")

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.F then
		useCardEvent:FireServer()
	end
end)
