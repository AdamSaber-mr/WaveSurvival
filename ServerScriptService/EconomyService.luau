-- EconomyService: het kassaboek van de scheidsrechter.
-- Alleen de server schrijft hierin; clients kunnen alleen meekijken.
-- Het saldo staat als Attribute ("Money") op de speler — Roblox kopieert
-- attributes automatisch naar alle clients, dus de HUD kan er direct naar kijken.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local EconomyService = {}

local function ensureWallet(player)
	if player:GetAttribute("Money") == nil then
		player:SetAttribute("Money", Config.Economy.StartMoney)
	end
end

Players.PlayerAdded:Connect(ensureWallet)
for _, player in ipairs(Players:GetPlayers()) do
	ensureWallet(player)
end

function EconomyService.get(player)
	return player:GetAttribute("Money") or 0
end

function EconomyService.add(player, amount)
	ensureWallet(player)
	player:SetAttribute("Money", EconomyService.get(player) + amount)
end

-- probeert te betalen; geeft true terug als het lukte
function EconomyService.spend(player, amount)
	-- geesten (spectators) kunnen niks kopen
	if player:GetAttribute("Spectator") == true then
		return false
	end
	ensureWallet(player)
	local balance = EconomyService.get(player)
	if balance < amount then
		return false
	end
	player:SetAttribute("Money", balance - amount)
	return true
end

return EconomyService
