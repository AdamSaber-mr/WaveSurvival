-- MysteryBoxService: de gok-kist (CoD Mystery Box).
-- E vasthouden → $950 → wapennamen flitsen boven de kist (steeds langzamer,
-- casino-gevoel) → de uitslag blijft staan → je hebt 10 seconden om hem te
-- pakken met E — anders sluit de kist en ben je je geld kwijt. Zo hoort het.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local EconomyService = require(script.Parent:WaitForChild("EconomyService"))
local WeaponInventory = require(script.Parent:WaitForChild("WeaponInventory"))

local boxConfig = Config.MysteryBox

local map = workspace:WaitForChild("Map")
local box = map:WaitForChild("MysteryBox")
local crate = box:WaitForChild("Crate")
local prompt = crate:WaitForChild("BoxPrompt")
local rollLabel = box:WaitForChild("Display"):WaitForChild("BillboardGui"):WaitForChild("RollLabel")

local rng = Random.new()
local busy = false
local currentWinner = nil   -- wie mag de prijs pakken
local currentPrize = nil
local prizeTaken = false

local defaultActionText = prompt.ActionText

local function showMessage(message)
	local originalText = prompt.ActionText
	prompt.ActionText = message
	task.delay(1.5, function()
		if prompt.Parent and prompt.ActionText == message then
			prompt.ActionText = originalText
		end
	end)
end

-- gewogen loting: zwaardere gewichten = grotere kans
local function pickWeighted()
	local total = 0
	for _, entry in ipairs(boxConfig.Pool) do
		total += entry.Weight
	end
	local roll = rng:NextNumber(0, total)
	for _, entry in ipairs(boxConfig.Pool) do
		roll -= entry.Weight
		if roll <= 0 then
			return entry.Weapon
		end
	end
	return boxConfig.Pool[#boxConfig.Pool].Weapon
end

local function runBox(player)
	busy = true

	-- roulette: namen flitsen, steeds langzamer
	local stepTime = 0.1
	local elapsed = 0
	while elapsed < boxConfig.RollTime do
		local randomEntry = boxConfig.Pool[rng:NextInteger(1, #boxConfig.Pool)]
		rollLabel.Text = randomEntry.Weapon
		task.wait(stepTime)
		elapsed += stepTime
		stepTime = stepTime * 1.15
	end

	-- de uitslag
	currentPrize = pickWeighted()
	currentWinner = player
	prizeTaken = false
	rollLabel.Text = "★ " .. currentPrize .. " ★"
	prompt.ActionText = "Take " .. currentPrize
	prompt.Enabled = true

	-- take-window
	local deadline = os.clock() + boxConfig.TakeTime
	while os.clock() < deadline and not prizeTaken do
		task.wait(0.1)
	end

	if prizeTaken then
		WeaponInventory.give(player, currentPrize)
		print(("[MysteryBox] %s won %s"):format(player.Name, currentPrize))
	else
		print(("[MysteryBox] %s liet %s liggen — kist dicht"):format(player.Name, tostring(currentPrize)))
	end

	-- kist sluit
	currentWinner = nil
	currentPrize = nil
	rollLabel.Text = ""
	prompt.ActionText = defaultActionText
	busy = false
end

prompt.Triggered:Connect(function(player)
	-- fase 2 van de flow: de winnaar pakt zijn prijs
	if currentWinner then
		if player == currentWinner then
			prizeTaken = true
		else
			showMessage("Not your prize!")
		end
		return
	end

	if busy then return end

	if not EconomyService.spend(player, boxConfig.Price) then
		showMessage("Not enough money!")
		return
	end

	prompt.Enabled = false -- tijdens de roulette even niet drukken
	task.spawn(runBox, player)
end)
