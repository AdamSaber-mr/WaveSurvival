-- HUDClient: houdt de geldteller op je scherm up-to-date.
-- De server plakt het saldo als "sticker" (Attribute) op de speler;
-- wij staren naar die sticker en werken de teller bij, met een "+100"-popup per verandering.

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- voorkom dubbel draaien (Script Sync-eigenaardigheid, net als bij GunClient)
if playerGui:GetAttribute("HUDClientHooked") then
	return
end
playerGui:SetAttribute("HUDClientHooked", true)

local hud = playerGui:WaitForChild("HUD")
local moneyLabel = hud:WaitForChild("MoneyLabel")

local function formatMoney(amount)
	return "$" .. tostring(amount)
end

-- klein zwevend "+100"-popje boven de teller
local function showPopup(delta)
	local popup = Instance.new("TextLabel")
	popup.AnchorPoint = Vector2.new(1, 1)
	popup.Position = UDim2.new(1, -24, 1, -70)
	popup.Size = UDim2.new(0, 160, 0, 30)
	popup.BackgroundTransparency = 1
	popup.Font = Enum.Font.Arcade
	popup.TextScaled = true
	popup.TextXAlignment = Enum.TextXAlignment.Right
	popup.TextColor3 = delta >= 0 and Color3.fromRGB(245, 205, 80) or Color3.fromRGB(235, 90, 90)
	popup.TextStrokeColor3 = Color3.fromRGB(20, 20, 25)
	popup.TextStrokeTransparency = 0.4
	popup.Text = (delta >= 0 and "+" or "") .. tostring(delta)
	popup.Parent = hud

	local tween = TweenService:Create(popup, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(1, -24, 1, -110),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})
	tween:Play()
	tween.Completed:Once(function()
		popup:Destroy()
	end)
end

local currentMoney = player:GetAttribute("Money") or 0
moneyLabel.Text = formatMoney(currentMoney)

player:GetAttributeChangedSignal("Money"):Connect(function()
	local newMoney = player:GetAttribute("Money") or 0
	local delta = newMoney - currentMoney
	currentMoney = newMoney
	moneyLabel.Text = formatMoney(newMoney)
	if delta ~= 0 then
		showPopup(delta)
	end
end)

-- ===== RONDES: nummer linksonder + grote aankondiging bij rondestart =====
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local roundLabel = hud:WaitForChild("RoundLabel")
local roundAnnounce = hud:WaitForChild("RoundAnnounce")

local function announceRound(round)
	roundAnnounce.Text = "WAVE " .. round
	roundAnnounce.TextTransparency = 0
	roundAnnounce.TextStrokeTransparency = 0.4
	local tween = TweenService:Create(roundAnnounce, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})
	task.delay(1.5, function()
		tween:Play()
	end)
end

local function updateRound()
	local round = ReplicatedStorage:GetAttribute("Round") or 0
	if round > 0 then
		roundLabel.Text = "WAVE " .. round
		announceRound(round)
	else
		roundLabel.Text = "WAVE -"
	end
end

updateRound()
ReplicatedStorage:GetAttributeChangedSignal("Round"):Connect(updateRound)

-- ===== AMMO: teller boven het geld (MAG / RESERVE, of RELOADING...) =====
local ammoLabel = hud:WaitForChild("AmmoLabel")
local currentTool = nil
local toolConnections = {}

local function formatReserve(reserve)
	return (reserve ~= nil and reserve < 0) and "∞" or tostring(reserve or 0)
end

local function updateAmmo()
	if not currentTool or currentTool:GetAttribute("Mag") == nil then
		ammoLabel.Text = ""
		return
	end
	if currentTool:GetAttribute("Reloading") then
		ammoLabel.Text = "RELOADING..."
	else
		ammoLabel.Text = string.upper(currentTool.Name) .. "  " .. tostring(currentTool:GetAttribute("Mag")) .. " / " .. formatReserve(currentTool:GetAttribute("Reserve"))
	end
end

local function setCurrentTool(tool)
	for _, connection in ipairs(toolConnections) do
		connection:Disconnect()
	end
	toolConnections = {}
	currentTool = tool
	if tool then
		for _, attributeName in ipairs({ "Mag", "Reserve", "Reloading" }) do
			table.insert(toolConnections, tool:GetAttributeChangedSignal(attributeName):Connect(updateAmmo))
		end
	end
	updateAmmo()
end

local function watchCharacter(character)
	character.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then setCurrentTool(child) end
	end)
	character.ChildRemoved:Connect(function(child)
		if child == currentTool then setCurrentTool(nil) end
	end)
	local equipped = character:FindFirstChildOfClass("Tool")
	if equipped then setCurrentTool(equipped) end
end

if player.Character then
	watchCharacter(player.Character)
end
player.CharacterAdded:Connect(watchCharacter)
