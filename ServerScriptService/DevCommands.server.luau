-- DevCommands: cheat-commando's voor het testen, via de chat.
-- BELANGRIJK: werkt ALLEEN in Studio (RunService:IsStudio) — in een gepubliceerde
-- game bestaan deze commando's dus niet en kan niemand ermee valsspelen.
--
--   /money [bedrag]   → geld (standaard 50000)
--   /god              → onsterfelijk (1.000.000 health; vervalt bij respawn)
--   /perks            → alle perks in één keer
--   /weapons          → SMG + Shotgun in je rugzak
--   /raygun           → de Ray Gun
--   /ammo             → magazijn + reserve vol van je huidige wapen
--   /card             → nieuwe willekeurige Fate-kaart
--   /tickets [n]      → tickets
--   /clear            → alle zombies opruimen
--   /kill             → jezelf doden (voor dood-tests)

local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	return -- nooit in het echt
end

local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local WeaponInventory = require(script.Parent:WaitForChild("WeaponInventory"))

local function makeCommand(name, callback)
	local command = Instance.new("TextChatCommand")
	command.Name = "Dev_" .. name
	command.PrimaryAlias = "/" .. name
	command.Triggered:Connect(function(originTextSource, text)
		local player = Players:GetPlayerByUserId(originTextSource.UserId)
		if not player then return end
		local args = string.split(text, " ")
		table.remove(args, 1)
		callback(player, args)
	end)
	command.Parent = TextChatService
end

makeCommand("money", function(player, args)
	local amount = tonumber(args[1]) or 50000
	player:SetAttribute("Money", amount)
	print("[Dev] " .. player.Name .. " → $" .. amount)
end)

makeCommand("god", function(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.MaxHealth = 1e6
		humanoid.Health = 1e6
		print("[Dev] " .. player.Name .. " → god-mode (vervalt bij respawn)")
	end
end)

makeCommand("perks", function(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	for perkName, perkConfig in pairs(Config.Perks) do
		player:SetAttribute("Perk_" .. perkName, true)
		if humanoid then
			if perkConfig.MaxHealth and humanoid.MaxHealth < 1e5 then
				humanoid.MaxHealth = perkConfig.MaxHealth
				humanoid.Health = perkConfig.MaxHealth
			end
			if perkConfig.WalkSpeed then
				humanoid.WalkSpeed = perkConfig.WalkSpeed
			end
		end
	end
	print("[Dev] " .. player.Name .. " → alle perks")
end)

makeCommand("weapons", function(player)
	WeaponInventory.give(player, "SMG")
	WeaponInventory.give(player, "Shotgun")
	print("[Dev] " .. player.Name .. " → SMG + Shotgun")
end)

makeCommand("raygun", function(player)
	WeaponInventory.give(player, "RayGun")
	print("[Dev] " .. player.Name .. " → Ray Gun")
end)

makeCommand("ammo", function(player)
	local tool = player.Character and player.Character:FindFirstChildOfClass("Tool")
	local weaponConfig = tool and Config.Weapons[tool.Name]
	if tool and weaponConfig then
		tool:SetAttribute("Mag", weaponConfig.MagSize)
		tool:SetAttribute("Reserve", weaponConfig.ReserveMax)
		print("[Dev] " .. player.Name .. " → ammo vol (" .. tool.Name .. ")")
	end
end)

makeCommand("card", function(player)
	local cardIds = {}
	for cardId in pairs(Config.Cards) do
		table.insert(cardIds, cardId)
	end
	table.sort(cardIds)
	local pick = cardIds[Random.new():NextInteger(1, #cardIds)]
	player:SetAttribute("Card", pick)
	player:SetAttribute("CardReady", true)
	print("[Dev] " .. player.Name .. " → kaart: " .. pick)
end)

makeCommand("tickets", function(player, args)
	local amount = tonumber(args[1]) or 100
	player:SetAttribute("Tickets", amount)
	print("[Dev] " .. player.Name .. " → tickets: " .. amount)
end)

makeCommand("clear", function(player)
	local zombiesFolder = workspace:FindFirstChild("Zombies")
	if not zombiesFolder then return end
	local count = 0
	for _, zombie in ipairs(zombiesFolder:GetChildren()) do
		local humanoid = zombie:FindFirstChildOfClass("Humanoid")
		if humanoid and humanoid.Health > 0 then
			humanoid.Health = 0
			count += 1
		end
	end
	print("[Dev] " .. player.Name .. " → " .. count .. " zombies opgeruimd")
end)

makeCommand("kill", function(player)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.MaxHealth = math.min(humanoid.MaxHealth, 100)
		humanoid.Health = 0
		print("[Dev] " .. player.Name .. " → gedood (test)")
	end
end)

print("[Dev] Cheat-commando's actief (alleen Studio): /money /god /perks /weapons /raygun /ammo /card /tickets /clear /kill")
