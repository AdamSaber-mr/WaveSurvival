-- WallBuyService: de wapenverkoper aan de muur (CoD wall-buys).
-- Houd E vast bij een wapen-bord → server checkt saldo → wapen in je rugzak.
-- Heb je het wapen al? Dan verkoopt het bord AMMO voor de halve prijs.
-- Het uitdelen zelf (incl. 2-wapen-limiet en dood-overleven) doet de wapen-kluis.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local EconomyService = require(script.Parent:WaitForChild("EconomyService"))
local WeaponInventory = require(script.Parent:WaitForChild("WeaponInventory"))

local map = workspace:WaitForChild("Map")
local wallBuysFolder = map:WaitForChild("WallBuys")

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
	local weaponConfig = Config.Weapons[weaponName]
	if not weaponConfig then return end

	-- al in bezit? → dan verkoopt het bord AMMO (CoD wall-buy regel)
	local ownedWeapon = WeaponInventory.find(player, weaponName)
	if ownedWeapon then
		local reserve = ownedWeapon:GetAttribute("Reserve") or 0
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
		ownedWeapon:SetAttribute("Reserve", weaponConfig.ReserveMax)
		showMessage(prompt, "Ammo refilled!")
		print(("[WallBuy] %s kocht ammo voor %s ($%d)"):format(player.Name, weaponName, weaponConfig.AmmoPrice))
		return
	end

	if not EconomyService.spend(player, price) then
		showMessage(prompt, "Not enough money!")
		return
	end

	WeaponInventory.give(player, weaponName)
	print(("[WallBuy] %s kocht %s voor $%d"):format(player.Name, weaponName, price))
end

-- alle wapen-borden aansluiten (toekomstige borden doen automatisch mee)
for _, station in ipairs(wallBuysFolder:GetChildren()) do
	for _, descendant in ipairs(station:GetDescendants()) do
		if descendant:IsA("ProximityPrompt") then
			descendant.Triggered:Connect(function(player)
				attemptWallBuy(player, station, descendant)
			end)
		end
	end
end
