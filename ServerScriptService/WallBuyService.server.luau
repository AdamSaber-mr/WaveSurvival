-- WallBuyService: de wapenverkoper aan de muur (CoD wall-buys).
-- Houd E vast bij een wapen-bord → server checkt saldo → wapen in je rugzak.
-- Max 2 wapens (CoD-regel): een derde koop vervangt het wapen dat je vasthoudt.

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local EconomyService = require(script.Parent:WaitForChild("EconomyService"))

local Players = game:GetService("Players")

local weaponTemplates = ServerStorage:WaitForChild("Weapons")
local map = workspace:WaitForChild("Map")
local wallBuysFolder = map:WaitForChild("WallBuys")

-- onthoud per speler welke wapens hij gekocht heeft — gekochte wapens
-- overleven de dood (bij respawn krijg je ze terug, met vers magazijn)
local purchasedWeapons = {} -- [player] = { SMG = true, ... }

local function isWeaponTool(instance)
	return instance:IsA("Tool") and Config.Weapons[instance.Name] ~= nil
end

-- alle wapens die de speler bezit (rugzak + in de hand)
local function ownedWeapons(player)
	local owned = {}
	for _, container in ipairs({ player:FindFirstChild("Backpack"), player.Character }) do
		if container then
			for _, child in ipairs(container:GetChildren()) do
				if isWeaponTool(child) then
					table.insert(owned, child)
				end
			end
		end
	end
	return owned
end

local function showMessage(prompt, message)
	local originalText = prompt.ActionText
	prompt.ActionText = message
	task.delay(1.5, function()
		if prompt.Parent then
			prompt.ActionText = originalText
		end
	end)
end

local function attemptWallBuy(player, station, prompt)
	local weaponName = station:GetAttribute("Weapon")
	local price = station:GetAttribute("Price") or 0
	local template = weaponTemplates:FindFirstChild(weaponName)
	if not template then
		warn("[WallBuy] template ontbreekt voor " .. tostring(weaponName))
		return
	end

	-- al in bezit? → dan verkoopt het bord AMMO (CoD wall-buy regel)
	for _, weapon in ipairs(ownedWeapons(player)) do
		if weapon.Name == weaponName then
			local weaponConfig = Config.Weapons[weaponName]
			local reserve = weapon:GetAttribute("Reserve") or 0
			if not weaponConfig.AmmoPrice or reserve < 0 then
				showMessage(prompt, "Already owned!")
				return
			end
			if reserve >= weaponConfig.ReserveMax then
				showMessage(prompt, "Ammo full!")
				return
			end
			if not EconomyService.spend(player, weaponConfig.AmmoPrice) then
				showMessage(prompt, "Not enough money!")
				return
			end
			weapon:SetAttribute("Reserve", weaponConfig.ReserveMax)
			showMessage(prompt, "Ammo refilled!")
			print(("[WallBuy] %s kocht ammo voor %s ($%d)"):format(player.Name, weaponName, weaponConfig.AmmoPrice))
			return
		end
	end

	if not EconomyService.spend(player, price) then
		showMessage(prompt, "Not enough money!")
		return
	end

	-- 2-wapen-limiet: vervang het wapen in de hand (of anders de eerste uit de rugzak)
	local owned = ownedWeapons(player)
	if #owned >= 2 then
		local equipped = player.Character and player.Character:FindFirstChildOfClass("Tool")
		local toRemove = (equipped and isWeaponTool(equipped)) and equipped or owned[1]
		if purchasedWeapons[player] then
			purchasedWeapons[player][toRemove.Name] = nil -- ingeruild = niet meer van jou
		end
		toRemove:Destroy()
	end

	purchasedWeapons[player] = purchasedWeapons[player] or {}
	purchasedWeapons[player][weaponName] = true

	local newWeapon = template:Clone()
	newWeapon.Parent = player:WaitForChild("Backpack")
	print(("[WallBuy] %s kocht %s voor $%d"):format(player.Name, weaponName, price))
end

for _, station in ipairs(wallBuysFolder:GetChildren()) do
	for _, descendant in ipairs(station:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") then
			descendant.Triggered:Connect(function(player)
				attemptWallBuy(player, station, descendant)
			end)
		end
	end
end

-- gekochte wapens teruggeven na de dood (de rugzak wordt bij respawn leeggeveegd)
local function watchRespawns(player)
	player.CharacterAdded:Connect(function()
		local backpack = player:WaitForChild("Backpack")
		task.wait(0.5) -- StarterPack eerst zijn werk laten doen
		local owned = purchasedWeapons[player]
		if not owned then return end
		for weaponName in pairs(owned) do
			-- 2-wapen-limiet geldt ook bij teruggeven na de dood
			if #ownedWeapons(player) >= 2 then break end
			local alreadyHas = backpack:FindFirstChild(weaponName)
				or (player.Character and player.Character:FindFirstChild(weaponName))
			local template = weaponTemplates:FindFirstChild(weaponName)
			if not alreadyHas and template then
				template:Clone().Parent = backpack
			end
		end
	end)
end
Players.PlayerAdded:Connect(watchRespawns)
for _, player in ipairs(Players:GetPlayers()) do
	watchRespawns(player)
end

Players.PlayerRemoving:Connect(function(player)
	purchasedWeapons[player] = nil
end)
