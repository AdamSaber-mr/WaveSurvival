-- WeaponInventory: de gedeelde wapen-kluis van de scheidsrechter.
-- Eén plek die regelt: wapens uitdelen, de 2-wapen-limiet (CoD-regel),
-- en onthouden wat van wie is zodat gekochte/gewonnen wapens de dood overleven.
-- Gebruikt door WallBuyService (borden) én MysteryBoxService (de box).

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local weaponTemplates = ServerStorage:WaitForChild("Weapons")

local WeaponInventory = {}

local purchasedWeapons = {} -- [player] = { SMG = true, ... }

function WeaponInventory.isWeaponTool(instance)
	return instance:IsA("Tool") and Config.Weapons[instance.Name] ~= nil
end

-- alle wapens die de speler bezit (rugzak + in de hand)
function WeaponInventory.owned(player)
	local owned = {}
	for _, container in ipairs({ player:FindFirstChild("Backpack"), player.Character }) do
		if container then
			for _, child in ipairs(container:GetChildren()) do
				if WeaponInventory.isWeaponTool(child) then
					table.insert(owned, child)
				end
			end
		end
	end
	return owned
end

function WeaponInventory.find(player, weaponName)
	for _, weapon in ipairs(WeaponInventory.owned(player)) do
		if weapon.Name == weaponName then
			return weapon
		end
	end
	return nil
end

-- geef een wapen (koop of box-prijs): respecteert de 2-wapen-limiet
-- en registreert het als "van jou" zodat het je dood overleeft
function WeaponInventory.give(player, weaponName)
	local template = weaponTemplates:FindFirstChild(weaponName)
	if not template then
		warn("[WeaponInventory] template ontbreekt voor " .. tostring(weaponName))
		return false
	end

	local owned = WeaponInventory.owned(player)
	if #owned >= 2 then
		-- vervang het wapen in de hand (of anders het eerste uit de rugzak)
		local equipped = player.Character and player.Character:FindFirstChildOfClass("Tool")
		local toRemove = (equipped and WeaponInventory.isWeaponTool(equipped)) and equipped or owned[1]
		if purchasedWeapons[player] then
			purchasedWeapons[player][toRemove.Name] = nil -- ingeruild = niet meer van jou
		end
		toRemove:Destroy()
	end

	purchasedWeapons[player] = purchasedWeapons[player] or {}
	purchasedWeapons[player][weaponName] = true

	template:Clone().Parent = player:WaitForChild("Backpack")
	return true
end

-- gekochte wapens teruggeven na de dood (de rugzak wordt bij respawn leeggeveegd)
local function watchRespawns(player)
	player.CharacterAdded:Connect(function()
		local backpack = player:WaitForChild("Backpack")
		task.wait(0.5) -- StarterPack eerst zijn werk laten doen
		local owned = purchasedWeapons[player]
		if not owned then return end
		for weaponName in pairs(owned) do
			-- 2-wapen-limiet geldt ook bij teruggeven
			if #WeaponInventory.owned(player) >= 2 then break end
			local alreadyHas = WeaponInventory.find(player, weaponName)
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

return WeaponInventory
