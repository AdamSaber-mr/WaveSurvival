-- GameStateService: leven, dood en de herstart (CoD-regels).
-- Sterf je? Dan word je een SPECTATOR-GEEST: doorzichtig, zombies negeren je,
-- kopen en schieten kan niet. Is IEDEREEN een geest → GAME OVER
-- ("Survived until wave X", in multiplayer met de laatste overlevende) → daarna
-- reset alles netjes naar wave 1: geld, wapens, perks, deuren — alsof je opnieuw begint.
-- Dit lost ook de spawn-camping op: dode spelers respawnen niet meer als hapklare brokjes.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local WeaponInventory = require(script.Parent:WaitForChild("WeaponInventory"))

local stateConfig = Config.GameState

-- de "reset-bel": andere systemen (RoundManager, ShopService) luisteren hiernaar
local resetEvent = Instance.new("BindableEvent")
resetEvent.Name = "GameReset"
resetEvent.Parent = ServerStorage

-- wij bepalen zelf wanneer spelers (her)spawnen
Players.CharacterAutoLoads = false

local gameOverBusy = false

local function isSpectator(player)
	return player:GetAttribute("Spectator") == true
end

local function alivePlayerCount()
	local count = 0
	for _, player in ipairs(Players:GetPlayers()) do
		if not isSpectator(player) then
			count += 1
		end
	end
	return count
end

-- maak van het nieuwe lichaam een doorzichtige geest zonder wapens
local function ghostify(character)
	task.wait(0.3) -- StarterPack en cosmetica eerst laten laden
	for _, part in ipairs(character:GetDescendants()) do
		if part:IsA("BasePart") and part.Transparency < 1 then
			part.Transparency = stateConfig.GhostTransparency
		elseif part:IsA("Decal") then
			part.Transparency = stateConfig.GhostTransparency
		elseif part:IsA("Tool") then
			part:Destroy()
		end
	end
	local player = Players:GetPlayerFromCharacter(character)
	local backpack = player and player:FindFirstChild("Backpack")
	if backpack then
		for _, tool in ipairs(backpack:GetChildren()) do
			if tool:IsA("Tool") then
				tool:Destroy()
			end
		end
	end
end

-- de grote schoonmaak: alles terug naar het begin
local function resetGame()
	print("[GameState] RESET — terug naar wave 1")
	resetEvent:Fire() -- RoundManager ruimt zombies op & herstart; ShopService zet de deuren terug

	for _, player in ipairs(Players:GetPlayers()) do
		player:SetAttribute("Spectator", nil)
		player:SetAttribute("Money", Config.Economy.StartMoney)
		player:SetAttribute("Kills", 0)
		player:SetAttribute("Card", nil)
		player:SetAttribute("CardReady", nil)
		player:SetAttribute("CardActiveUntil", nil)
		-- perks worden door PerkService gewist bij CharacterAdded
		WeaponInventory.reset(player)
		player:LoadCharacter()
	end

	ReplicatedStorage:SetAttribute("GameOver", nil)
	ReplicatedStorage:SetAttribute("LastSurvivor", nil)
end

local function triggerGameOver(lastPlayer)
	if gameOverBusy then return end
	gameOverBusy = true

	local wave = ReplicatedStorage:GetAttribute("Round") or 0
	if #Players:GetPlayers() > 1 and lastPlayer then
		ReplicatedStorage:SetAttribute("LastSurvivor", lastPlayer.Name)
	end
	ReplicatedStorage:SetAttribute("GameOver", wave)
	print(("[GameState] GAME OVER op wave %d"):format(wave))

	task.wait(stateConfig.GameOverDuration)
	resetGame()
	gameOverBusy = false
end

local function onDied(player)
	if isSpectator(player) then return end
	player:SetAttribute("Spectator", true)

	if alivePlayerCount() == 0 then
		-- iedereen is neer: deze speler was de laatste overlevende
		task.spawn(triggerGameOver, player)
		return
	end

	-- er vechten nog anderen door: kom terug als geest en kijk mee
	task.delay(stateConfig.RespawnDelay, function()
		if player.Parent and isSpectator(player) then
			player:LoadCharacter()
		end
	end)
end

local function watchCharacter(player, character)
	local humanoid = character:WaitForChild("Humanoid", 5)
	if not humanoid then return end
	if isSpectator(player) then
		ghostify(character)
		player.CameraMode = Enum.CameraMode.Classic -- geesten mogen vrij rondkijken
	else
		player.CameraMode = Enum.CameraMode.LockFirstPerson -- levenden spelen first person
	end
	humanoid.Died:Connect(function()
		onDied(player)
	end)
end

local function watchPlayer(player)
	player.CharacterAdded:Connect(function(character)
		watchCharacter(player, character)
	end)
	-- eerste spawn (CharacterAutoLoads staat uit, dus wij doen het)
	player:LoadCharacter()
end

Players.PlayerAdded:Connect(watchPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	player.CharacterAdded:Connect(function(character)
		watchCharacter(player, character)
	end)
	if player.Character then
		watchCharacter(player, player.Character)
	else
		player:LoadCharacter()
	end
end
