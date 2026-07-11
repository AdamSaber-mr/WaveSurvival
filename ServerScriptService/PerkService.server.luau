-- PerkService: de frisdrankautomaten (CoD perks).
-- E vasthouden bij een automaat → betalen → perk actief als sticker op de speler
-- (Perk_<naam> = true) + effect direct toegepast. Sterf je, dan ben je ze kwijt —
-- de wrede CoD-regel die perks juist waardevol maakt.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local EconomyService = require(script.Parent:WaitForChild("EconomyService"))

local map = workspace:WaitForChild("Map")
local machinesFolder = map:WaitForChild("PerkMachines")

local function showMessage(prompt, message)
	local originalText = prompt.ActionText
	prompt.ActionText = message
	task.delay(1.5, function()
		if prompt.Parent then
			prompt.ActionText = originalText
		end
	end)
end

-- effect van een perk toepassen op het huidige lichaam van de speler
local function applyPerkEffect(player, perkName)
	local perkConfig = Config.Perks[perkName]
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not (perkConfig and humanoid) then return end

	if perkConfig.MaxHealth then
		humanoid.MaxHealth = perkConfig.MaxHealth
		humanoid.Health = perkConfig.MaxHealth -- vol drinken = vol leven
	end
	if perkConfig.WalkSpeed then
		humanoid.WalkSpeed = perkConfig.WalkSpeed
	end
	-- ReloadMultiplier wordt door WeaponServer gelezen bij het herladen
end

local function attemptPerkBuy(player, machine, prompt)
	local perkName = machine:GetAttribute("Perk")
	local price = machine:GetAttribute("Price") or 0
	if not Config.Perks[perkName] then return end

	if player:GetAttribute("Perk_" .. perkName) then
		showMessage(prompt, "Already active!")
		return
	end
	if not EconomyService.spend(player, price) then
		showMessage(prompt, "Not enough money!")
		return
	end

	player:SetAttribute("Perk_" .. perkName, true)
	applyPerkEffect(player, perkName)
	showMessage(prompt, "Enjoy!")
	print(("[Perks] %s dronk %s ($%d)"):format(player.Name, perkName, price))
end

for _, machine in ipairs(machinesFolder:GetChildren()) do
	for _, descendant in ipairs(machine:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") then
			descendant.Triggered:Connect(function(player)
				attemptPerkBuy(player, machine, descendant)
			end)
		end
	end
end

-- de wrede regel: dood = alle perks kwijt
local function watchPlayer(player)
	player.CharacterAdded:Connect(function()
		for perkName in pairs(Config.Perks) do
			player:SetAttribute("Perk_" .. perkName, nil)
		end
		-- nieuw lichaam heeft vanzelf weer standaard health/snelheid
	end)
end
Players.PlayerAdded:Connect(watchPlayer)
for _, player in ipairs(Players:GetPlayers()) do
	watchPlayer(player)
end
