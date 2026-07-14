-- CardService: de Fate & Fortune-kaarten (CoD Spaceland-stijl).
-- Elke wave krijgt iedere speler één willekeurige kaart. Activeren met F →
-- effect voor ~20 seconden (HUD toont een badge met aftel-timer) → kaart verbruikt.
-- Volgende wave: nieuwe kaart.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local useCardEvent = Instance.new("RemoteEvent")
useCardEvent.Name = "UseCard"
useCardEvent.Parent = remotes

local cardIds = {}
for cardId in pairs(Config.Cards) do
	table.insert(cardIds, cardId)
end
table.sort(cardIds) -- vaste volgorde, dan is de loting eerlijk herhaalbaar
local rng = Random.new()

-- deel een nieuwe kaart uit (bij elke nieuwe wave)
local function dealCard(player)
	local cardId = cardIds[rng:NextInteger(1, #cardIds)]
	player:SetAttribute("Card", cardId)
	player:SetAttribute("CardReady", true)
end

-- effect aanzetten, en na de duur weer netjes uitzetten
local function activateCard(player)
	local cardId = player:GetAttribute("Card")
	local cardConfig = cardId and Config.Cards[cardId]
	if not cardConfig then return end
	if player:GetAttribute("CardReady") ~= true then return end

	if player:GetAttribute("Spectator") == true then return end -- geesten spelen geen kaarten
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	player:SetAttribute("CardReady", false)
	player:SetAttribute("CardActiveUntil", workspace:GetServerTimeNow() + cardConfig.Duration)

	-- effect toepassen
	if cardConfig.SpeedBonus then
		humanoid.WalkSpeed += cardConfig.SpeedBonus
	end
	if cardConfig.DamageMultiplier then
		player:SetAttribute("Card_DamageBoost", cardConfig.DamageMultiplier)
	end
	if cardConfig.DamageTakenMultiplier then
		player:SetAttribute("Card_DamageResist", cardConfig.DamageTakenMultiplier)
	end
	print(("[Cards] %s activeerde %s"):format(player.Name, cardConfig.DisplayName))

	task.delay(cardConfig.Duration, function()
		-- effect uitzetten (alleen als het lichaam nog hetzelfde is)
		if cardConfig.SpeedBonus and player.Character == character and humanoid.Health > 0 then
			humanoid.WalkSpeed = math.max(humanoid.WalkSpeed - cardConfig.SpeedBonus, 8)
		end
		player:SetAttribute("Card_DamageBoost", nil)
		player:SetAttribute("Card_DamageResist", nil)
		player:SetAttribute("Card", nil) -- verbruikt; volgende wave een nieuwe
	end)
end

useCardEvent.OnServerEvent:Connect(activateCard)

-- nieuwe wave = nieuwe kaart voor iedereen die er nog geen (bruikbare) heeft
ReplicatedStorage:GetAttributeChangedSignal("Round"):Connect(function()
	local round = ReplicatedStorage:GetAttribute("Round") or 0
	if round <= 0 then return end
	for _, player in ipairs(Players:GetPlayers()) do
		if player:GetAttribute("Spectator") ~= true then
			dealCard(player)
		end
	end
end)

-- dood: actieve effecten opruimen (je dealt-kaart mag je houden)
local function watchPlayer(player)
	player.CharacterAdded:Connect(function()
		player:SetAttribute("Card_DamageBoost", nil)
		player:SetAttribute("Card_DamageResist", nil)
		player:SetAttribute("CardActiveUntil", nil)
	end)
end
Players.PlayerAdded:Connect(watchPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	watchPlayer(player)
end
