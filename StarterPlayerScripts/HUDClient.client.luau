-- HUDClient: de complete Spaceland-HUD (CoD IW Zombies-stijl), volledig uit code.
--  · rechtsboven:  filmklapper met gestreepte klap-arm en handgeschreven SCENE-nummer
--  · linksonder:   popart portret-kaart (jouw echte Roblox-avatar) + tickets + geld
--  · onder-midden: perk-icoontjes met kleurgradient
--  · rechtsonder:  Fate-kaart met kaartstapel, medaillon en gouden randen (F = activeren)
-- De server plakt alle waarden als stickers (Attributes); wij tekenen alleen.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local player = Players.LocalPlayer

local playerGui = player:WaitForChild("PlayerGui")
if playerGui:GetAttribute("HUDClientHooked") then
	return
end
playerGui:SetAttribute("HUDClientHooked", true)

-- Roblox' eigen health-balk rechtsboven uit (we tekenen zelf onze HUD)
pcall(function()
	game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
end)

-- oude HUD's opruimen
for _, name in ipairs({ "HUD", "SpacelandHUD", "SpacelandOverlay" }) do
	local legacy = playerGui:FindFirstChild(name)
	if legacy then legacy:Destroy() end
end

-- ===================== STIJL-GEREEDSCHAP =====================
local GOLD = Color3.fromRGB(232, 190, 96)
local GOLD_DARK = Color3.fromRGB(170, 128, 52)
local INK = Color3.fromRGB(16, 16, 20)
local PAPER = Color3.fromRGB(240, 238, 232)
local GREY = Color3.fromRGB(165, 165, 175)

local function addCorner(object, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = object
	return corner
end

local function addStroke(object, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.Transparency = transparency or 0
	stroke.Parent = object
	return stroke
end

local function addGradient(object, colorTop, colorBottom, rotation)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(colorTop, colorBottom)
	gradient.Rotation = rotation or 90
	gradient.Parent = object
	return gradient
end

-- zachte slagschaduw: donkere tweeling nét achter het element
local function addShadow(frame, radius, offset)
	local shadow = Instance.new("Frame")
	shadow.Name = frame.Name .. "Shadow"
	shadow.AnchorPoint = frame.AnchorPoint
	shadow.Position = frame.Position + UDim2.new(0, offset or 4, 0, offset or 4)
	shadow.Size = frame.Size
	shadow.Rotation = frame.Rotation
	shadow.BackgroundColor3 = Color3.new(0, 0, 0)
	shadow.BackgroundTransparency = 0.55
	shadow.ZIndex = frame.ZIndex - 1
	addCorner(shadow, radius)
	shadow.Parent = frame.Parent
	return shadow
end

local function label(parent, props)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.GothamBlack
	l.TextScaled = true
	for k, v in pairs(props) do l[k] = v end
	l.Parent = parent
	return l
end

-- ===================== DE HUD =====================
local hud = Instance.new("ScreenGui")
hud.Name = "SpacelandHUD"
hud.ResetOnSpawn = false
hud.Parent = playerGui

-- ---------- RECHTSBOVEN: de filmklapper (mini, rond, clean) ----------
local clapper = Instance.new("Frame")
clapper.Name = "Clapper"
clapper.AnchorPoint = Vector2.new(1, 0)
clapper.Position = UDim2.new(1, -30, 0, 30)
clapper.Size = UDim2.new(0, 92, 0, 62)
clapper.Rotation = -6
clapper.BackgroundColor3 = Color3.fromRGB(38, 38, 44)
clapper.ZIndex = 2
clapper.Parent = hud
addCorner(clapper, 9)
addGradient(clapper, Color3.fromRGB(52, 52, 60), Color3.fromRGB(24, 24, 30))
addStroke(clapper, Color3.fromRGB(12, 12, 16), 1.5, 0.1)
addShadow(clapper, 9, 4)

-- de klap-arm: strepen als hard-stop kleurverloop (blijven perfect binnen de ronde hoeken)
local arm = Instance.new("Frame")
arm.Name = "ClapperArm"
arm.Size = UDim2.new(1, 0, 0, 18)
arm.BackgroundColor3 = PAPER
arm.ZIndex = 3
arm.Parent = clapper
addCorner(arm, 9)
local W = Color3.fromRGB(240, 238, 232)
local B = Color3.fromRGB(18, 18, 22)
local stripeGradient = Instance.new("UIGradient")
stripeGradient.Rotation = 8
stripeGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0.000, W), ColorSequenceKeypoint.new(0.110, W),
	ColorSequenceKeypoint.new(0.112, B), ColorSequenceKeypoint.new(0.221, B),
	ColorSequenceKeypoint.new(0.223, W), ColorSequenceKeypoint.new(0.332, W),
	ColorSequenceKeypoint.new(0.334, B), ColorSequenceKeypoint.new(0.443, B),
	ColorSequenceKeypoint.new(0.445, W), ColorSequenceKeypoint.new(0.554, W),
	ColorSequenceKeypoint.new(0.556, B), ColorSequenceKeypoint.new(0.665, B),
	ColorSequenceKeypoint.new(0.667, W), ColorSequenceKeypoint.new(0.776, W),
	ColorSequenceKeypoint.new(0.778, B), ColorSequenceKeypoint.new(0.887, B),
	ColorSequenceKeypoint.new(0.889, W), ColorSequenceKeypoint.new(1.000, W),
})
stripeGradient.Parent = arm
-- dun naadje tussen arm en bord
local seam = Instance.new("Frame")
seam.Position = UDim2.new(0, 0, 0, 18)
seam.Size = UDim2.new(1, 0, 0, 1)
seam.BackgroundColor3 = Color3.fromRGB(90, 90, 100)
seam.BackgroundTransparency = 0.4
seam.BorderSizePixel = 0
seam.ZIndex = 3
seam.Parent = clapper

label(clapper, {
	Name = "SceneWord",
	Position = UDim2.new(0, 8, 0, 32),
	Size = UDim2.new(0, 42, 0, 18),
	Text = "SCENE",
	Font = Enum.Font.Oswald,
	TextColor3 = PAPER,
	TextXAlignment = Enum.TextXAlignment.Left,
	ZIndex = 3,
})
local sceneNumber = label(clapper, {
	Name = "SceneNumber",
	Position = UDim2.new(0, 52, 0, 24),
	Size = UDim2.new(0, 32, 0, 34),
	Text = "-",
	Font = Enum.Font.Oswald,
	TextColor3 = PAPER,
	TextXAlignment = Enum.TextXAlignment.Right,
	ZIndex = 3,
})

-- ---------- LINKSONDER: portret-kaart + tickets + geld ----------
local portrait = Instance.new("Frame")
portrait.Name = "PortraitCard"
portrait.AnchorPoint = Vector2.new(0, 1)
portrait.Position = UDim2.new(0, 42, 1, -46)
portrait.Size = UDim2.new(0, 94, 0, 122)
portrait.Rotation = -4
portrait.BackgroundColor3 = PAPER
portrait.ZIndex = 2
portrait.Parent = hud
addCorner(portrait, 8)
addShadow(portrait, 8)
local portraitStroke = addStroke(portrait, Color3.fromRGB(235, 120, 60), 3.5)
local strokeGradient = Instance.new("UIGradient")
strokeGradient.Color = ColorSequence.new(Color3.fromRGB(250, 160, 70), Color3.fromRGB(215, 85, 45))
strokeGradient.Rotation = 90
strokeGradient.Parent = portraitStroke

local avatar = Instance.new("ImageLabel")
avatar.Name = "Avatar"
avatar.Position = UDim2.new(0, 5, 0, 5)
avatar.Size = UDim2.new(0, 84, 0, 84)
avatar.BackgroundColor3 = Color3.fromRGB(110, 150, 210)
avatar.Image = "rbxthumb://type=AvatarHeadShot&id=" .. player.UserId .. "&w=150&h=150"
avatar.ZIndex = 3
avatar.Parent = portrait
addCorner(avatar, 6)
addGradient(avatar, Color3.fromRGB(130, 170, 225), Color3.fromRGB(80, 110, 170))

-- comic-sticker "SPACELAND" schuin over de onderkant
local sticker = label(portrait, {
	Name = "Sticker",
	Position = UDim2.new(0, -6, 1, -30),
	Size = UDim2.new(1, 12, 0, 24),
	Rotation = -6,
	Text = "SPACELAND",
	Font = Enum.Font.Bangers,
	TextColor3 = Color3.fromRGB(255, 226, 66),
	BackgroundColor3 = Color3.fromRGB(214, 44, 140),
	BackgroundTransparency = 0,
	ZIndex = 4,
})
addCorner(sticker, 6)
addStroke(sticker, Color3.fromRGB(120, 20, 80), 2)
addGradient(sticker, Color3.fromRGB(232, 62, 158), Color3.fromRGB(168, 28, 118))

-- tickets en geld op donkere plaatjes (zoals de referentie)
local ticketsPlate = Instance.new("Frame")
ticketsPlate.Name = "TicketsPlate"
ticketsPlate.AnchorPoint = Vector2.new(0, 1)
ticketsPlate.Position = UDim2.new(0, 152, 1, -100)
ticketsPlate.Size = UDim2.new(0, 100, 0, 26)
ticketsPlate.BackgroundColor3 = INK
ticketsPlate.BackgroundTransparency = 0.35
ticketsPlate.Parent = hud
addCorner(ticketsPlate, 6)
local ticketsLabel = label(ticketsPlate, {
	Name = "Tickets",
	Position = UDim2.new(0, 10, 0, 3),
	Size = UDim2.new(1, -16, 1, -6),
	Text = "🎟  0",
	Font = Enum.Font.GothamBold,
	TextColor3 = PAPER,
	TextXAlignment = Enum.TextXAlignment.Left,
})

local moneyPlate = Instance.new("Frame")
moneyPlate.Name = "MoneyPlate"
moneyPlate.AnchorPoint = Vector2.new(0, 1)
moneyPlate.Position = UDim2.new(0, 152, 1, -60)
moneyPlate.Size = UDim2.new(0, 128, 0, 32)
moneyPlate.BackgroundColor3 = INK
moneyPlate.BackgroundTransparency = 0.35
moneyPlate.Parent = hud
addCorner(moneyPlate, 6)
local moneyLabel = label(moneyPlate, {
	Name = "Money",
	Position = UDim2.new(0, 10, 0, 3),
	Size = UDim2.new(1, -16, 1, -6),
	Text = "$500",
	TextColor3 = GOLD,
	TextXAlignment = Enum.TextXAlignment.Left,
})
addGradient(moneyLabel, Color3.fromRGB(255, 222, 120), Color3.fromRGB(212, 160, 60))

-- ---------- ONDER-MIDDEN: perk-icoontjes ----------
local perkBar = Instance.new("Frame")
perkBar.Name = "PerkBar"
perkBar.AnchorPoint = Vector2.new(0.5, 1)
perkBar.Position = UDim2.new(0.5, 0, 1, -26)
perkBar.Size = UDim2.new(0, 260, 0, 36)
perkBar.BackgroundTransparency = 1
perkBar.Parent = hud
local perkLayout = Instance.new("UIListLayout")
perkLayout.FillDirection = Enum.FillDirection.Horizontal
perkLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
perkLayout.Padding = UDim.new(0, 8)
perkLayout.Parent = perkBar

local PERK_EMOJI = { Juggernog = "✚", SpeedCola = "🥤", StaminUp = "🏃" }

-- ---------- RECHTSONDER: de Fate-kaart met stapeltje ----------
-- twee kaarten "achter" de hoofdkaart voor het stapel-effect
for i, rot in ipairs({ 10, -5 }) do
	local behind = Instance.new("Frame")
	behind.Name = "CardBehind" .. i
	behind.AnchorPoint = Vector2.new(1, 1)
	behind.Position = UDim2.new(1, -26 - i * 3, 1, -32)
	behind.Size = UDim2.new(0, 106, 0, 148)
	behind.Rotation = rot
	behind.BackgroundColor3 = Color3.fromRGB(52, 14, 20)
	behind.ZIndex = 1
	behind.Parent = hud
	addCorner(behind, 10)
	addStroke(behind, GOLD_DARK, 1.5, 0.4)
end

local fateCard = Instance.new("Frame")
fateCard.Name = "FateCard"
fateCard.AnchorPoint = Vector2.new(1, 1)
fateCard.Position = UDim2.new(1, -30, 1, -30)
fateCard.Size = UDim2.new(0, 108, 0, 150)
fateCard.Rotation = 3
fateCard.BackgroundColor3 = Color3.fromRGB(104, 22, 32)
fateCard.ZIndex = 3
fateCard.Parent = hud
addCorner(fateCard, 10)
addGradient(fateCard, Color3.fromRGB(122, 30, 42), Color3.fromRGB(66, 12, 22))
addStroke(fateCard, GOLD, 2.5)
addShadow(fateCard, 10)

-- dubbele sier-rand binnenin (het "ornate" gevoel)
local innerBorder = Instance.new("Frame")
innerBorder.Position = UDim2.new(0, 5, 0, 5)
innerBorder.Size = UDim2.new(1, -10, 1, -10)
innerBorder.BackgroundTransparency = 1
innerBorder.ZIndex = 3
innerBorder.Parent = fateCard
addCorner(innerBorder, 7)
addStroke(innerBorder, GOLD, 1, 0.55)

label(fateCard, {
	Name = "CardTop",
	Position = UDim2.new(0, 6, 0, 8),
	Size = UDim2.new(1, -12, 0, 18),
	Text = "FATE CARD",
	Font = Enum.Font.Bangers,
	TextColor3 = GOLD,
	ZIndex = 4,
})

-- medaillon: gouden ring + oranje munt met het kaart-embleem
local medallion = Instance.new("Frame")
medallion.Name = "Medallion"
medallion.AnchorPoint = Vector2.new(0.5, 0)
medallion.Position = UDim2.new(0.5, 0, 0, 30)
medallion.Size = UDim2.new(0, 66, 0, 66)
medallion.BackgroundColor3 = Color3.fromRGB(238, 150, 52)
medallion.ZIndex = 4
medallion.Parent = fateCard
addCorner(medallion, 33)
addGradient(medallion, Color3.fromRGB(248, 176, 78), Color3.fromRGB(198, 96, 30))
addStroke(medallion, GOLD, 3)
local innerRing = Instance.new("Frame")
innerRing.AnchorPoint = Vector2.new(0.5, 0.5)
innerRing.Position = UDim2.new(0.5, 0, 0.5, 0)
innerRing.Size = UDim2.new(0, 56, 0, 56)
innerRing.BackgroundTransparency = 1
innerRing.ZIndex = 4
innerRing.Parent = medallion
addCorner(innerRing, 28)
addStroke(innerRing, Color3.fromRGB(120, 52, 16), 1.5, 0.3)
local cardEmoji = label(medallion, {
	Name = "CardEmoji",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	Size = UDim2.new(0, 44, 0, 44),
	Text = "—",
	TextColor3 = PAPER,
	ZIndex = 5,
})

-- naam-banier onderaan de kaart
local nameBanner = Instance.new("Frame")
nameBanner.Name = "NameBanner"
nameBanner.AnchorPoint = Vector2.new(0.5, 1)
nameBanner.Position = UDim2.new(0.5, 0, 1, -26)
nameBanner.Size = UDim2.new(1, -14, 0, 24)
nameBanner.BackgroundColor3 = Color3.fromRGB(40, 8, 14)
nameBanner.BackgroundTransparency = 0.2
nameBanner.ZIndex = 4
nameBanner.Parent = fateCard
addCorner(nameBanner, 5)
local cardName = label(nameBanner, {
	Name = "CardName",
	Size = UDim2.new(1, 0, 1, 0),
	Text = "NO CARD",
	Font = Enum.Font.Bangers,
	TextColor3 = PAPER,
	ZIndex = 4,
})
local cardHint = label(fateCard, {
	Name = "CardHint",
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -6),
	Size = UDim2.new(1, -14, 0, 16),
	Text = "press  F",
	Font = Enum.Font.GothamBold,
	TextColor3 = GOLD,
	ZIndex = 4,
})
-- zachte puls op de hint zodat je 'm niet mist
task.spawn(function()
	while cardHint.Parent do
		TweenService:Create(cardHint, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { TextTransparency = 0.55 }):Play()
		task.wait(0.85)
		TweenService:Create(cardHint, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), { TextTransparency = 0 }):Play()
		task.wait(0.85)
	end
end)

-- actieve-kaart-badge: gouden munt met aftel-timer + wijzertje naar de kaart
local badge = Instance.new("Frame")
badge.Name = "ActiveBadge"
badge.AnchorPoint = Vector2.new(1, 1)
badge.Position = UDim2.new(1, -56, 1, -192)
badge.Size = UDim2.new(0, 42, 0, 42)
badge.BackgroundColor3 = Color3.fromRGB(238, 140, 44)
badge.Visible = false
badge.ZIndex = 4
badge.Parent = hud
addCorner(badge, 21)
addGradient(badge, Color3.fromRGB(250, 170, 66), Color3.fromRGB(200, 100, 28))
addStroke(badge, GOLD, 2.5)
local badgeInner = Instance.new("Frame")
badgeInner.AnchorPoint = Vector2.new(0.5, 0.5)
badgeInner.Position = UDim2.new(0.5, 0, 0.5, 0)
badgeInner.Size = UDim2.new(0, 33, 0, 33)
badgeInner.BackgroundTransparency = 1
badgeInner.ZIndex = 4
badgeInner.Parent = badge
addCorner(badgeInner, 17)
addStroke(badgeInner, Color3.fromRGB(130, 60, 16), 1.5, 0.35)
local badgeText = label(badge, {
	Name = "Seconds",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	Size = UDim2.new(0, 34, 0, 30),
	Text = "20",
	TextColor3 = INK,
	ZIndex = 5,
})
local pointer = label(hud, {
	Name = "BadgePointer",
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -66, 1, -172),
	Size = UDim2.new(0, 22, 0, 14),
	Text = "▼",
	TextColor3 = GOLD,
	Visible = false,
	ZIndex = 4,
})

-- ammo links naast de kaart, op een donker plaatje
local ammoPlate = Instance.new("Frame")
ammoPlate.Name = "AmmoPlate"
ammoPlate.AnchorPoint = Vector2.new(1, 1)
ammoPlate.Position = UDim2.new(1, -156, 1, -34)
ammoPlate.Size = UDim2.new(0, 160, 0, 56)
ammoPlate.BackgroundColor3 = INK
ammoPlate.BackgroundTransparency = 0.35
ammoPlate.Parent = hud
addCorner(ammoPlate, 8)
local weaponLabel = label(ammoPlate, {
	Name = "WeaponName",
	Position = UDim2.new(0, 8, 0, 4),
	Size = UDim2.new(1, -16, 0, 18),
	Text = "",
	Font = Enum.Font.GothamBold,
	TextColor3 = GREY,
	TextXAlignment = Enum.TextXAlignment.Right,
})
local magLabel = label(ammoPlate, {
	Name = "Mag",
	Position = UDim2.new(0, 8, 0, 20),
	Size = UDim2.new(0.55, 0, 0, 32),
	Text = "",
	TextColor3 = PAPER,
	TextXAlignment = Enum.TextXAlignment.Right,
})
local reserveLabel = label(ammoPlate, {
	Name = "Reserve",
	Position = UDim2.new(0.58, 0, 0, 30),
	Size = UDim2.new(0.4, -8, 0, 20),
	Text = "",
	Font = Enum.Font.GothamBold,
	TextColor3 = GREY,
	TextXAlignment = Enum.TextXAlignment.Left,
})

-- grote wave-aankondiging in het midden
local announce = label(hud, {
	Name = "WaveAnnounce",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.3, 0),
	Size = UDim2.new(0, 560, 0, 92),
	Text = "",
	Font = Enum.Font.Bangers,
	TextColor3 = Color3.fromRGB(228, 72, 72),
	TextTransparency = 1,
})

-- ===================== DE HUD LATEN LEVEN =====================

-- geld + zwevende popup
local function formatMoney(amount) return "$" .. tostring(amount) end
local currentMoney = player:GetAttribute("Money") or 0
moneyLabel.Text = formatMoney(currentMoney)

local function showMoneyPopup(delta)
	local popup = label(hud, {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 162, 1, -102),
		Size = UDim2.new(0, 140, 0, 28),
		Text = (delta >= 0 and "+" or "") .. tostring(delta),
		TextColor3 = delta >= 0 and GOLD or Color3.fromRGB(235, 90, 90),
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local tween = TweenService:Create(popup, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 162, 1, -140),
		TextTransparency = 1,
	})
	tween:Play()
	tween.Completed:Once(function() popup:Destroy() end)
end

player:GetAttributeChangedSignal("Money"):Connect(function()
	local newMoney = player:GetAttribute("Money") or 0
	local delta = newMoney - currentMoney
	currentMoney = newMoney
	moneyLabel.Text = formatMoney(newMoney)
	if delta ~= 0 then showMoneyPopup(delta) end
end)

-- tickets
local function updateTickets()
	ticketsLabel.Text = "🎟  " .. tostring(player:GetAttribute("Tickets") or 0)
end
updateTickets()
player:GetAttributeChangedSignal("Tickets"):Connect(updateTickets)

-- wave in de klapper + aankondiging
local function announceWave(round)
	announce.Text = "WAVE " .. round
	announce.TextTransparency = 0
	local tween = TweenService:Create(announce, TweenInfo.new(1.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		TextTransparency = 1,
	})
	task.delay(1.5, function() tween:Play() end)
end
local function updateRound()
	local round = ReplicatedStorage:GetAttribute("Round") or 0
	sceneNumber.Text = round > 0 and tostring(round) or "-"
	if round > 0 then announceWave(round) end
end
updateRound()
ReplicatedStorage:GetAttributeChangedSignal("Round"):Connect(updateRound)

-- perk-icoontjes
local perkIcons = {}
local function updatePerkIcons()
	for perkName, perkConfig in pairs(Config.Perks) do
		local hasPerk = player:GetAttribute("Perk_" .. perkName) == true
		local icon = perkIcons[perkName]
		if hasPerk and not icon then
			icon = label(perkBar, {
				Name = perkName,
				Size = UDim2.new(0, 36, 0, 36),
				Text = PERK_EMOJI[perkName] or "?",
				TextColor3 = PAPER,
				BackgroundColor3 = perkConfig.Color,
				BackgroundTransparency = 0,
			})
			addCorner(icon, 9)
			addGradient(icon, perkConfig.Color, Color3.new(
				perkConfig.Color.R * 0.55, perkConfig.Color.G * 0.55, perkConfig.Color.B * 0.55))
			addStroke(icon, INK, 2, 0.3)
			perkIcons[perkName] = icon
		elseif not hasPerk and icon then
			icon:Destroy()
			perkIcons[perkName] = nil
		end
	end
end
updatePerkIcons()
for perkName in pairs(Config.Perks) do
	player:GetAttributeChangedSignal("Perk_" .. perkName):Connect(updatePerkIcons)
end

-- ammo van het vastgehouden wapen
local currentTool = nil
local toolConnections = {}
local function updateAmmo()
	if not currentTool or currentTool:GetAttribute("Mag") == nil then
		ammoPlate.Visible = false
		return
	end
	ammoPlate.Visible = true
	weaponLabel.Text = string.upper(currentTool.Name)
	if currentTool:GetAttribute("Reloading") then
		magLabel.Text = "···"
		reserveLabel.Text = "reload"
	else
		magLabel.Text = tostring(currentTool:GetAttribute("Mag"))
		local reserve = currentTool:GetAttribute("Reserve")
		reserveLabel.Text = "/ " .. ((reserve ~= nil and reserve < 0) and "∞" or tostring(reserve or 0))
	end
end
local function setCurrentTool(tool)
	for _, connection in ipairs(toolConnections) do connection:Disconnect() end
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
if player.Character then watchCharacter(player.Character) end
player.CharacterAdded:Connect(watchCharacter)

-- fate-kaart
local function updateCard()
	local cardId = player:GetAttribute("Card")
	local cardConfig = cardId and Config.Cards[cardId]
	if cardConfig then
		cardEmoji.Text = cardConfig.Emoji
		cardName.Text = cardConfig.DisplayName
		cardHint.Visible = player:GetAttribute("CardReady") == true
		medallion.BackgroundTransparency = 0
	else
		cardEmoji.Text = "—"
		cardName.Text = "NO CARD"
		cardHint.Visible = false
		medallion.BackgroundTransparency = 0.35
	end
end
updateCard()
player:GetAttributeChangedSignal("Card"):Connect(updateCard)
player:GetAttributeChangedSignal("CardReady"):Connect(updateCard)

-- badge met aftel-timer
RunService.Heartbeat:Connect(function()
	local activeUntil = player:GetAttribute("CardActiveUntil") or 0
	local remaining = activeUntil - workspace:GetServerTimeNow()
	local active = remaining > 0
	badge.Visible = active
	pointer.Visible = active
	if active then
		badgeText.Text = tostring(math.ceil(remaining))
	end
end)

-- ===================== DOOD, SPECTATOR & GAME OVER =====================

-- "YOU DIED": grote rode tekst die kort in beeld klapt
local youDied = label(hud, {
	Name = "YouDied",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.38, 0),
	Size = UDim2.new(0, 600, 0, 110),
	Text = "YOU DIED",
	Font = Enum.Font.Bangers,
	TextColor3 = Color3.fromRGB(200, 40, 40),
	TextTransparency = 1,
	ZIndex = 10,
})

-- klein persistent "SPECTATING"-label zolang je een geest bent
local spectating = label(hud, {
	Name = "Spectating",
	AnchorPoint = Vector2.new(0.5, 0),
	Position = UDim2.new(0.5, 0, 0, 24),
	Size = UDim2.new(0, 300, 0, 30),
	Text = "SPECTATING",
	Font = Enum.Font.GothamBold,
	TextColor3 = GREY,
	Visible = false,
	ZIndex = 10,
})

local function updateSpectator()
	local isGhost = player:GetAttribute("Spectator") == true
	spectating.Visible = isGhost and ReplicatedStorage:GetAttribute("GameOver") == nil
	if isGhost then
		-- de dood-klap: fel in beeld, dan langzaam vervagen
		youDied.TextTransparency = 0
		local tween = TweenService:Create(youDied, TweenInfo.new(1.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			TextTransparency = 1,
		})
		task.delay(1.2, function() tween:Play() end)
	end
end
player:GetAttributeChangedSignal("Spectator"):Connect(updateSpectator)

-- GAME OVER: donkere overlay in een eigen laag die het HELE scherm bedekt
-- (IgnoreGuiInset = true dekt ook de strook onder Roblox' bovenbalk af)
local overlayGui = Instance.new("ScreenGui")
overlayGui.Name = "SpacelandOverlay"
overlayGui.ResetOnSpawn = false
overlayGui.IgnoreGuiInset = true
overlayGui.DisplayOrder = 10
overlayGui.Parent = playerGui

local overlay = Instance.new("Frame")
overlay.Name = "GameOverOverlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 1
overlay.Visible = false
overlay.ZIndex = 11
overlay.Parent = overlayGui

local gameOverTitle = label(overlay, {
	Name = "Title",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.36, 0),
	Size = UDim2.new(0, 640, 0, 120),
	Text = "GAME OVER",
	Font = Enum.Font.Bangers,
	TextColor3 = Color3.fromRGB(210, 45, 45),
	ZIndex = 12,
})
local gameOverSub = label(overlay, {
	Name = "Subtitle",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.52, 0),
	Size = UDim2.new(0, 520, 0, 40),
	Text = "",
	Font = Enum.Font.GothamBold,
	TextColor3 = PAPER,
	ZIndex = 12,
})
local gameOverSurvivor = label(overlay, {
	Name = "Survivor",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 0, 0.60, 0),
	Size = UDim2.new(0, 520, 0, 30),
	Text = "",
	Font = Enum.Font.GothamBold,
	TextColor3 = GOLD,
	ZIndex = 12,
})

local function updateGameOver()
	local wave = ReplicatedStorage:GetAttribute("GameOver")
	if wave then
		overlay.Visible = true
		overlay.BackgroundTransparency = 1
		gameOverSub.Text = "SURVIVED UNTIL WAVE " .. wave
		local survivor = ReplicatedStorage:GetAttribute("LastSurvivor")
		gameOverSurvivor.Text = survivor and ("LAST SURVIVOR: " .. string.upper(survivor)) or ""
		spectating.Visible = false
		TweenService:Create(overlay, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 0.35,
		}):Play()
	else
		overlay.Visible = false
	end
end
updateGameOver()
ReplicatedStorage:GetAttributeChangedSignal("GameOver"):Connect(updateGameOver)

-- ===================== CROSSHAIR (first person) =====================
-- klein, clean: een dot met vier korte streepjes eromheen
local crosshair = Instance.new("Frame")
crosshair.Name = "Crosshair"
crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
crosshair.Position = UDim2.new(0.5, 0, 0.5, 0)
crosshair.Size = UDim2.new(0, 24, 0, 24)
crosshair.BackgroundTransparency = 1
crosshair.ZIndex = 9
crosshair.Parent = hud

local dot = Instance.new("Frame")
dot.AnchorPoint = Vector2.new(0.5, 0.5)
dot.Position = UDim2.new(0.5, 0, 0.5, 0)
dot.Size = UDim2.new(0, 3, 0, 3)
dot.BackgroundColor3 = PAPER
dot.BackgroundTransparency = 0.15
dot.Parent = crosshair
addCorner(dot, 2)

local TICKS = {
	{ UDim2.new(0.5, 0, 0, 2), UDim2.new(0, 2, 0, 6) },   -- boven
	{ UDim2.new(0.5, 0, 1, -2), UDim2.new(0, 2, 0, 6) },  -- onder
	{ UDim2.new(0, 2, 0.5, 0), UDim2.new(0, 6, 0, 2) },   -- links
	{ UDim2.new(1, -2, 0.5, 0), UDim2.new(0, 6, 0, 2) },  -- rechts
}
for _, tick in ipairs(TICKS) do
	local t = Instance.new("Frame")
	t.AnchorPoint = Vector2.new(0.5, 0.5)
	t.Position = tick[1]
	t.Size = tick[2]
	t.BackgroundColor3 = PAPER
	t.BackgroundTransparency = 0.35
	t.BorderSizePixel = 0
	t.Parent = crosshair
end

-- crosshair verbergen voor geesten en tijdens game over
local function updateCrosshair()
	crosshair.Visible = player:GetAttribute("Spectator") ~= true
		and ReplicatedStorage:GetAttribute("GameOver") == nil
end
updateCrosshair()
player:GetAttributeChangedSignal("Spectator"):Connect(updateCrosshair)
ReplicatedStorage:GetAttributeChangedSignal("GameOver"):Connect(updateCrosshair)

-- ===================== BLOEDSCHERM (schade-feedback) =====================
-- rode gloed langs de schermranden die opflitst als je geraakt wordt,
-- en blijft pulseren zolang je bijna dood bent (CoD-stijl)
local bloodVignette = Instance.new("Frame")
bloodVignette.Name = "BloodVignette"
bloodVignette.Size = UDim2.new(1, 0, 1, 0)
bloodVignette.BackgroundColor3 = Color3.fromRGB(150, 10, 10)
bloodVignette.BackgroundTransparency = 1
bloodVignette.BorderSizePixel = 0
bloodVignette.ZIndex = 8
bloodVignette.Parent = overlayGui  -- dekt het hele scherm, ook onder de bovenbalk
local vignetteGradient = Instance.new("UIGradient")
vignetteGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0),
	NumberSequenceKeypoint.new(0.35, 1),
	NumberSequenceKeypoint.new(0.65, 1),
	NumberSequenceKeypoint.new(1, 0),
})
vignetteGradient.Rotation = 90
vignetteGradient.Parent = bloodVignette

local vignetteTarget = 1 -- 1 = onzichtbaar
local function flashDamage(amount)
	local intensity = math.clamp(amount / 40, 0.25, 0.75)
	bloodVignette.BackgroundTransparency = 1 - intensity
end

local lastHealth = nil
local function watchHealth(character)
	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then return end
	lastHealth = humanoid.Health
	humanoid.HealthChanged:Connect(function(newHealth)
		if lastHealth and newHealth < lastHealth then
			flashDamage(lastHealth - newHealth)
		end
		lastHealth = newHealth
	end)
end
if player.Character then watchHealth(player.Character) end
player.CharacterAdded:Connect(watchHealth)

-- uitfaden + laag-leven-puls in één hartslag-loop
RunService.Heartbeat:Connect(function(deltaTime)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local lowHealth = humanoid and humanoid.Health > 0 and humanoid.MaxHealth < 1e5
		and (humanoid.Health / humanoid.MaxHealth) < 0.35
	local floor = 1
	if lowHealth then
		floor = 0.72 + math.sin(os.clock() * 5) * 0.08 -- bange hartslag
	end
	local current = bloodVignette.BackgroundTransparency
	bloodVignette.BackgroundTransparency = math.min(current + deltaTime * 1.4, floor)
end)
