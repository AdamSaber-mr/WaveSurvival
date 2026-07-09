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
